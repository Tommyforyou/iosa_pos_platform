<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PurchaseReceipt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Supplier;
use App\Models\Purchase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\PurchaseReceiptLine;


class PurchaseReceiptController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | List Purchase Receipts
    |--------------------------------------------------------------------------
    */

    public function index()
    {
        return PurchaseReceipt::with('lines')
            ->latest()
            ->limit(200)
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Upload Purchase Receipt
    |--------------------------------------------------------------------------
    | Uploads scanned receipt/invoice document.
    | OCR extraction will be added in the next phase.
    */

    public function upload(Request $request)
    {
        $validated = $request->validate([
            'document' => [
                'required',
                'file',
                'mimes:jpg,jpeg,png,pdf',
                'max:10240',
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Store Document
        |--------------------------------------------------------------------------
        */

        $path = $validated['document']->store(
            'purchase-receipts',
            'public'
        );

        /*
        |--------------------------------------------------------------------------
        | Create Pending Receipt Record
        |--------------------------------------------------------------------------
        */

        $receipt = PurchaseReceipt::create([
            'business_id' => 1,
            'document_path' => $path,
            'status' => 'pending_ocr',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Purchase receipt uploaded successfully',
            'receipt' => $receipt,
            'document_url' => asset('storage/' . $path),
        ]);
    }


    /*
    |--------------------------------------------------------------------------
    | Convert Reviewed Receipt To Purchase
    |--------------------------------------------------------------------------
    */

    public function convertToPurchase(Request $request, PurchaseReceipt $purchaseReceipt)
    {

        // Validate Payment Status
        $validated = $request->validate([
            'payment_status' => [
                'required',
                'in:paid,unpaid',
            ],
        ]);


        if ($purchaseReceipt->status !== 'reviewed') {
            return response()->json([
                'success' => false,
                'message' => 'Only reviewed receipts can be converted to purchases.',
            ], 422);
        }

        $existingPurchase = Purchase::where(
            'purchase_receipt_id',
            $purchaseReceipt->id
        )->first();

        if ($existingPurchase) {
            return response()->json([
                'success' => false,
                'message' => 'This receipt has already been converted to a purchase.',
                'purchase' => $existingPurchase->load(['supplier', 'items']),
            ], 422);
        }

        return DB::transaction(function () use ($purchaseReceipt,  $validated) {


            $supplier = Supplier::firstOrCreate(
                [
                    'brn' => $purchaseReceipt->supplier_brn,
                ],
                [
                    'business_id' => $purchaseReceipt->business_id ?? 1,
                    'name' => $purchaseReceipt->supplier_name ?? 'Unknown Supplier',
                    'vat_number' => $purchaseReceipt->supplier_vat_number,
                    'is_active' => true,
                ]
            );


            $totalAmount =
                (float) $purchaseReceipt->total_incl_vat;

            $isPaid =
                $validated['payment_status'] === 'paid';


            $purchase = Purchase::create([
                'business_id' => $purchaseReceipt->business_id ?? 1,
                'supplier_id' => $supplier->id,
                'purchase_receipt_id' => $purchaseReceipt->id,
                'invoice_number' => $purchaseReceipt->invoice_number,
                'invoice_date' => $purchaseReceipt->invoice_date,
                'subtotal_excl_vat' => $purchaseReceipt->subtotal_excl_vat,
                'vat_amount' => $purchaseReceipt->vat_amount,
                'total_incl_vat' => $purchaseReceipt->total_incl_vat,
                'status' => 'posted',
                'payment_status' => $isPaid ? 'paid' : 'unpaid',
                'paid_amount' => $isPaid ? $totalAmount : 0,
                'balance_amount' => $isPaid ? 0 : $totalAmount,
                'paid_at' => $isPaid ? now() : null,
            ]);

            /*
            |--------------------------------------------------------------------------
            | Create Purchase Items From Receipt Lines
            |--------------------------------------------------------------------------
            */

            if ($purchaseReceipt->lines()->exists()) {
                foreach ($purchaseReceipt->lines as $line) {
                    $purchase->items()->create([
                        'description' => $line->description,
                        'quantity' => $line->quantity,
                        'unit_price' => $line->unit_price,
                        'line_total' => $line->line_total,
                    ]);
                }
            } else {
                /*
                |--------------------------------------------------------------------------
                | Fallback Item
                |--------------------------------------------------------------------------
                */

                $purchase->items()->create([
                    'description' => 'Purchase captured from OCR receipt',
                    'quantity' => 1,
                    'unit_price' => $purchaseReceipt->subtotal_excl_vat,
                    'line_total' => $purchaseReceipt->subtotal_excl_vat,
                ]);
            }

            $purchaseReceipt->update([
                'status' => 'converted',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Receipt converted to purchase successfully.',
                'purchase' => $purchase->fresh(['supplier', 'items']),
            ]);
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Run OCR
    |--------------------------------------------------------------------------
    | Runs local Tesseract OCR on uploaded image receipts.
    */

    public function runOcr(PurchaseReceipt $purchaseReceipt)
    {
        if (!$purchaseReceipt->document_path) {
            return response()->json([
                'success' => false,
                'message' => 'No document found for this purchase receipt.',
            ], 422);
        }

        $fullPath = storage_path(
            'app/public/' . $purchaseReceipt->document_path
        );

        if (!file_exists($fullPath)) {
            return response()->json([
                'success' => false,
                'message' => 'Document file not found on server.',
            ], 404);
        }

        /*
        |--------------------------------------------------------------------------
        | Run Tesseract OCR
        |--------------------------------------------------------------------------
        */

        $command = 'tesseract ' .
            escapeshellarg($fullPath) .
            ' stdout';

        $rawText = shell_exec($command);

        if (!$rawText) {
            return response()->json([
                'success' => false,
                'message' => 'OCR failed or returned no text.',
            ], 500);
        }

        /*
        |--------------------------------------------------------------------------
        | Basic Extraction
        |--------------------------------------------------------------------------
        */

        $extracted = $this->extractPurchaseFieldsFromText($rawText);
        /*
        |--------------------------------------------------------------------------
        | Extract Receipt Line Items
        |--------------------------------------------------------------------------
        */

        $receiptLines = $this->extractPurchaseLinesFromText($rawText);

        /*
        |--------------------------------------------------------------------------
        | Update Receipt
        |--------------------------------------------------------------------------
        */

        $purchaseReceipt->update([
            'ocr_raw_text' => $rawText,
            'ocr_extracted_data' => $extracted,
            'supplier_name' => $extracted['supplier_name'] ?? null,
            'supplier_brn' => $extracted['supplier_brn'] ?? null,
            'supplier_vat_number' => $extracted['supplier_vat_number'] ?? null,
            'invoice_number' => $extracted['invoice_number'] ?? null,
            'invoice_date' => $extracted['invoice_date'] ?? null,
            'subtotal_excl_vat' => $extracted['subtotal_excl_vat'] ?? 0,
            'vat_amount' => $extracted['vat_amount'] ?? 0,
            'total_incl_vat' => $extracted['total_incl_vat'] ?? 0,
            'status' => 'pending_review',
            'ocr_confidence' => 50,
        ]);
        /*
        |--------------------------------------------------------------------------
        | Save OCR Line Items
        |--------------------------------------------------------------------------
        | Remove old OCR lines first so running OCR again does not duplicate lines.
        */

        $purchaseReceipt->lines()->delete();

        foreach ($receiptLines as $line) {
            $purchaseReceipt->lines()->create([
                'description' => $line['description'],
                'quantity' => $line['quantity'],
                'unit_price' => $line['unit_price'],
                'line_total' => $line['line_total'],
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'OCR completed. Please review extracted fields.',
            'receipt' => $purchaseReceipt->fresh('lines'),
        ]);
    }



    /*
    |--------------------------------------------------------------------------
    | Delete Purchase Receipt
    |--------------------------------------------------------------------------
    */

    public function destroy(PurchaseReceipt $purchaseReceipt)
    {
        if ($purchaseReceipt->document_path) {
            Storage::disk('public')->delete(
                $purchaseReceipt->document_path
            );
        }

        $purchaseReceipt->delete();

        return response()->json([
            'success' => true,
            'message' => 'Purchase receipt deleted successfully',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Extract Purchase Fields From OCR Text
    |--------------------------------------------------------------------------
    | Basic regex extraction for Mauritian purchase invoices.
    */

    private function extractPurchaseFieldsFromText(string $text): array
    {
        $cleanText = preg_replace('/\s+/', ' ', $text);

        $data = [
            'supplier_name' => null,
            'supplier_brn' => null,
            'supplier_vat_number' => null,
            'invoice_number' => null,
            'invoice_date' => null,
            'subtotal_excl_vat' => 0,
            'vat_amount' => 0,
            'total_incl_vat' => 0,
        ];

        /*
        |--------------------------------------------------------------------------
        | Supplier Name
        |--------------------------------------------------------------------------
        | Simple first-line fallback.
        */

        $lines = preg_split('/\r\n|\r|\n/', trim($text));

        if (!empty($lines[0])) {
            $data['supplier_name'] = trim($lines[0]);
        }

        /*
        |--------------------------------------------------------------------------
        | BRN
        |--------------------------------------------------------------------------
        */

        if (preg_match('/BRN[:\s]*([A-Z0-9]+)/i', $cleanText, $match)) {
            $data['supplier_brn'] = $match[1];
        }

        /*
        |--------------------------------------------------------------------------
        | VAT Number
        |--------------------------------------------------------------------------
        */

        if (preg_match('/VAT(?:\s*No\.?|\s*Number)?[:\s]*([A-Z0-9]+)/i', $cleanText, $match)) {
            $data['supplier_vat_number'] = $match[1];
        }

        /*
        |--------------------------------------------------------------------------
        | Invoice Number
        |--------------------------------------------------------------------------
        */

        if (preg_match('/(?:Invoice|Inv)\s*(?:No\.?|Number)?[:\s#-]*([A-Z0-9\-\/]+)/i', $cleanText, $match)) {
            $data['invoice_number'] = $match[1];
        }

        /*
        |--------------------------------------------------------------------------
        | Date
        |--------------------------------------------------------------------------
        */

        if (preg_match('/(\d{2}[\/\-]\d{2}[\/\-]\d{4})/', $cleanText, $match)) {
            $parts = preg_split('/[\/\-]/', $match[1]);

            if (count($parts) === 3) {
                $data['invoice_date'] = $parts[2] . '-' . $parts[1] . '-' . $parts[0];
            }
        }

        /*
        |--------------------------------------------------------------------------
        | VAT Amount
        |--------------------------------------------------------------------------
        */

        if (preg_match('/VAT[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match)) {
            $data['vat_amount'] = (float) str_replace(',', '', $match[1]);
        }

        /*
        |--------------------------------------------------------------------------
        | Total Incl VAT
        |--------------------------------------------------------------------------
        */

        if (preg_match('/(?:Total|Amount Due|Grand Total)[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match)) {
            $data['total_incl_vat'] = (float) str_replace(',', '', $match[1]);
        }

        /*
        |--------------------------------------------------------------------------
        | Subtotal Excl VAT
        |--------------------------------------------------------------------------
        */

        if (preg_match('/(?:Subtotal|Sub Total|Total Excl\.? VAT|Excl\.? VAT)[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match)) {
            $data['subtotal_excl_vat'] = (float) str_replace(',', '', $match[1]);
        } elseif ($data['total_incl_vat'] > 0 && $data['vat_amount'] > 0) {
            $data['subtotal_excl_vat'] =
                $data['total_incl_vat'] - $data['vat_amount'];
        }

        return $data;
    }

    /*
    |--------------------------------------------------------------------------
    | Update Reviewed Purchase Receipt
    |--------------------------------------------------------------------------
    | Used after OCR/manual review.
    */

    public function update(Request $request, PurchaseReceipt $purchaseReceipt)
    {
        $validated = $request->validate([
            'supplier_name' => ['nullable', 'string', 'max:255'],
            'supplier_brn' => ['nullable', 'string', 'max:255'],
            'supplier_vat_number' => ['nullable', 'string', 'max:255'],
            'invoice_number' => ['nullable', 'string', 'max:255'],
            'invoice_date' => ['nullable', 'date'],
            'subtotal_excl_vat' => ['nullable', 'numeric'],
            'vat_amount' => ['nullable', 'numeric'],
            'total_incl_vat' => ['nullable', 'numeric'],
            'status' => ['nullable', 'string', 'max:100'],
        ]);

        $purchaseReceipt->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Purchase receipt updated successfully',
            'receipt' => $purchaseReceipt->fresh('lines'),
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Extract Purchase Lines From OCR Text
|--------------------------------------------------------------------------
| Handles both clean invoice lines and noisy OCR pipe-style lines.
*/

    private function extractPurchaseLinesFromText(string $text): array
    {
        $lines = preg_split('/\r\n|\r|\n/', trim($text));

        $items = [];

        foreach ($lines as $line) {
            $originalLine = trim($line);

            if ($originalLine === '') {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Skip Non Item Lines
            |--------------------------------------------------------------------------
            */

            if (preg_match('/(subtotal|sub total|grand total|vat|amount due|invoice|brn|date|client|shipping|phone|address|logo|website|tracking)/i', $originalLine)) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Normalise OCR Line
            |--------------------------------------------------------------------------
            */

            $line = str_replace(['|', '[', ']', '{', '}', '—', '“', '”', '‘', '’'], ' ', $originalLine);
            $line = preg_replace('/\s+/', ' ', $line);
            $line = trim($line);

            /*
            |--------------------------------------------------------------------------
            | Extract Numbers
            |--------------------------------------------------------------------------
            */

            preg_match_all('/\d+(?:[.,]\d{1,3})*/', $line, $numberMatches);

            $numbers = $numberMatches[0] ?? [];

            if (count($numbers) < 2) {
                continue;
            }

            /*
        |--------------------------------------------------------------------------
        | Extract Description
        |--------------------------------------------------------------------------
        */

            $description = preg_replace('/\d+(?:[.,]\d{1,3})*/', '', $line);
            $description = preg_replace('/\s+/', ' ', trim($description));

            if ($description === '' || strlen($description) < 3) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Convert Numbers
            |--------------------------------------------------------------------------
            */

            $parsedNumbers = array_map(function ($number) {
                return $this->parseOcrNumber($number);
            }, $numbers);

            $parsedNumbers = array_values(array_filter($parsedNumbers, function ($number) {
                return $number !== null && $number > 0;
            }));

            if (count($parsedNumbers) < 2) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Determine Quantity, Unit Price And Total
            |--------------------------------------------------------------------------
            | Strategy:
            | - Last number is usually line total.
            | - Previous number is usually unit price.
            | - First small number is usually quantity.
            */

            $lineTotal = $parsedNumbers[count($parsedNumbers) - 1];
            $unitPrice = $parsedNumbers[count($parsedNumbers) - 2];

            $quantity = 1;

            foreach ($parsedNumbers as $number) {
                if ($number > 0 && $number <= 1000) {
                    $quantity = $number;
                    break;
                }
            }

            /*
            |--------------------------------------------------------------------------
            | Strong Item Sanity Filter
            |--------------------------------------------------------------------------
            */

            if (
                preg_match('/(citystate|address|phone|invoice|ship|bill|subtotal|balance|terms|condition|due|receipt|payment|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i', $description)
            ) {
                continue;
            }

            if (strlen($description) < 4 || strlen($description) > 80) {
                continue;
            }

            if ($quantity <= 0 || $quantity > 500) {
                continue;
            }

            if ($unitPrice <= 0 || $unitPrice > 100000) {
                continue;
            }

            if ($lineTotal <= 0 || $lineTotal > 1000000) {
                continue;
            }

            $expectedTotal = round($quantity * $unitPrice, 2);

            /*
            |--------------------------------------------------------------------------
            | Loose Total Validation
            |--------------------------------------------------------------------------
            | OCR often separates quantity, price and totals badly.
            | We keep candidates for human review.
            */


            if (
                $expectedTotal > 0 &&
                $lineTotal > 0 &&
                abs($expectedTotal - $lineTotal) > max(1000, $lineTotal * 5)
            ) {
                continue;
            }


            $items[] = [
                'description' => $description,
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'line_total' => $lineTotal,
            ];
        }

        /*
        |--------------------------------------------------------------------------
        | Fallback To Block Style Extraction
        |--------------------------------------------------------------------------
        */

        if (empty($items)) {
            $items = $this->extractBlockStylePurchaseLines($text);
        }


        Log::info('OCR ITEMS EXTRACTED', [
            'items' => $items,
        ]);

        return $items;
    }

    /*
|--------------------------------------------------------------------------
| Extract Block Style Purchase Lines
|--------------------------------------------------------------------------
| Handles invoices where item names and prices appear in separate OCR blocks.
*/

    private function extractBlockStylePurchaseLines(string $text): array
    {
        $lines = preg_split('/\r\n|\r|\n/', trim($text));

        $descriptions = [];
        $prices = [];

        foreach ($lines as $line) {
            $line = trim($line);

            if ($line === '') {
                continue;
            }

            /*
        |--------------------------------------------------------------------------
        | Detect Numbered Product Lines
        |--------------------------------------------------------------------------
        */

            if (preg_match('/^\d+\s+([A-Za-z].+)$/', $line, $match)) {
                $description = trim($match[1]);
                if (preg_match('/(street|colorado|fairbanks|u\.s\.a|address|invoice|bill|ship|subtotal|total|balance|terms|condition|due|receipt|phone|zip|date|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i', $description)) {
                    continue;
                }

                if (strlen($description) < 4 || strlen($description) > 80) {
                    continue;
                }

                $descriptions[] = $description;

                continue;
            }

            /*
        |--------------------------------------------------------------------------
        | Detect Price Lines
        |--------------------------------------------------------------------------
        */

            if (preg_match('/^(\d+(?:[.,]\d{2})?)\s+(\d+(?:[.,]\d{2})?)$/', $line, $match)) {
                $unitPrice = $this->parseOcrNumber($match[1]);
                $lineTotal = $this->parseOcrNumber($match[2]);

                if ($unitPrice > 0 && $lineTotal > 0) {
                    $prices[] = [
                        'unit_price' => $unitPrice,
                        'line_total' => $lineTotal,
                    ];
                }
            }
        }

        $items = [];

        $count = min(count($descriptions), count($prices));

        for ($i = 0; $i < $count; $i++) {
            $items[] = [
                'description' => $descriptions[$i],
                'quantity' => 1,
                'unit_price' => $prices[$i]['unit_price'],
                'line_total' => $prices[$i]['line_total'],
            ];
        }

        return $items;
    }
    /*
|--------------------------------------------------------------------------
| Parse OCR Number
|--------------------------------------------------------------------------
*/

    private function parseOcrNumber(string $value): ?float
    {
        $value = trim($value);

        /*
        |--------------------------------------------------------------------------
        | Remove Non Numeric Characters
        |--------------------------------------------------------------------------
        */

        $value = preg_replace('/[^\d,\.]/', '', $value);

        if ($value === '') {
            return null;
        }

        /*
        |--------------------------------------------------------------------------
        | Handle European / Mauritian Format
        |--------------------------------------------------------------------------
        | Example:
        | 11.750,00 => 11750.00
        | 1,250.50  => 1250.50
        */

        if (preg_match('/^\d{1,3}(\.\d{3})+,\d{2}$/', $value)) {
            $value = str_replace('.', '', $value);
            $value = str_replace(',', '.', $value);
        } else {
            $value = str_replace(',', '', $value);
        }

        return is_numeric($value) ? (float) $value : null;
    }

    /*
|--------------------------------------------------------------------------
| Store Receipt Line
|--------------------------------------------------------------------------
*/

    public function storeLine(
        Request $request,
        PurchaseReceipt $purchaseReceipt
    ) {
        $validated = $request->validate([
            'description' => ['required', 'string', 'max:255'],
            'quantity' => ['required', 'numeric', 'min:0.001'],
            'unit_price' => ['required', 'numeric', 'min:0'],
            'line_total' => ['required', 'numeric', 'min:0'],
        ]);

        $line = $purchaseReceipt->lines()->create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Line added successfully.',
            'line' => $line,
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Update Receipt Line
|--------------------------------------------------------------------------
*/

    public function updateLine(
        Request $request,
        PurchaseReceiptLine $line
    ) {
        $validated = $request->validate([
            'description' => ['required', 'string', 'max:255'],
            'quantity' => ['required', 'numeric', 'min:0.001'],
            'unit_price' => ['required', 'numeric', 'min:0'],
            'line_total' => ['required', 'numeric', 'min:0'],
        ]);

        $line->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Line updated successfully.',
            'line' => $line,
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Delete Receipt Line
|--------------------------------------------------------------------------
*/

    public function deleteLine(
        PurchaseReceiptLine $line
    ) {
        $line->delete();

        return response()->json([
            'success' => true,
            'message' => 'Line deleted successfully.',
        ]);
    }
}
