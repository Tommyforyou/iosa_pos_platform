<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PurchaseReceipt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Supplier;
use App\Models\Purchase;
use Illuminate\Support\Facades\DB;

class PurchaseReceiptController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | List Purchase Receipts
    |--------------------------------------------------------------------------
    */

    public function index() {
        return PurchaseReceipt::with( 'lines' )
        ->latest()
        ->limit( 200 )
        ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Upload Purchase Receipt
    |--------------------------------------------------------------------------
    | Uploads scanned receipt/invoice document.
    | OCR extraction will be added in the next phase.
    */

    public function upload( Request $request ) {
        $validated = $request->validate( [
            'document' => [
                'required',
                'file',
                'mimes:jpg,jpeg,png,pdf',
                'max:10240',
            ],
        ] );

        /*
        |--------------------------------------------------------------------------
        | Store Document
        |--------------------------------------------------------------------------
        */

        $path = $validated[ 'document' ]->store(
            'purchase-receipts',
            'public'
        );

        /*
        |--------------------------------------------------------------------------
        | Create Pending Receipt Record
        |--------------------------------------------------------------------------
        */

        $receipt = PurchaseReceipt::create( [
            'business_id' => 1,
            'document_path' => $path,
            'status' => 'pending_ocr',
        ] );

        return response()->json( [
            'success' => true,
            'message' => 'Purchase receipt uploaded successfully',
            'receipt' => $receipt,
            'document_url' => asset( 'storage/' . $path ),
        ] );
    }

   
   /*
|--------------------------------------------------------------------------
| Convert Reviewed Receipt To Purchase
|--------------------------------------------------------------------------
*/

public function convertToPurchase(PurchaseReceipt $purchaseReceipt)
{
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

    return DB::transaction(function () use ($purchaseReceipt) {
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
        ]);

        $purchase->items()->create([
            'description' => 'Purchase captured from OCR receipt',
            'quantity' => 1,
            'unit_price' => $purchaseReceipt->subtotal_excl_vat,
            'line_total' => $purchaseReceipt->subtotal_excl_vat,
        ]);

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

    public function runOcr( PurchaseReceipt $purchaseReceipt ) {
        if ( !$purchaseReceipt->document_path ) {
            return response()->json( [
                'success' => false,
                'message' => 'No document found for this purchase receipt.',
            ], 422 );
        }

        $fullPath = storage_path(
            'app/public/' . $purchaseReceipt->document_path
        );

        if ( !file_exists( $fullPath ) ) {
            return response()->json( [
                'success' => false,
                'message' => 'Document file not found on server.',
            ], 404 );
        }

        /*
        |--------------------------------------------------------------------------
        | Run Tesseract OCR
        |--------------------------------------------------------------------------
        */

        $command = 'tesseract ' .
        escapeshellarg( $fullPath ) .
        ' stdout';

        $rawText = shell_exec( $command );

        if ( !$rawText ) {
            return response()->json( [
                'success' => false,
                'message' => 'OCR failed or returned no text.',
            ], 500 );
        }

        /*
        |--------------------------------------------------------------------------
        | Basic Extraction
        |--------------------------------------------------------------------------
        */

        $extracted = $this->extractPurchaseFieldsFromText( $rawText );

        /*
        |--------------------------------------------------------------------------
        | Update Receipt
        |--------------------------------------------------------------------------
        */

        $purchaseReceipt->update( [
            'ocr_raw_text' => $rawText,
            'ocr_extracted_data' => $extracted,
            'supplier_name' => $extracted[ 'supplier_name' ] ?? null,
            'supplier_brn' => $extracted[ 'supplier_brn' ] ?? null,
            'supplier_vat_number' => $extracted[ 'supplier_vat_number' ] ?? null,
            'invoice_number' => $extracted[ 'invoice_number' ] ?? null,
            'invoice_date' => $extracted[ 'invoice_date' ] ?? null,
            'subtotal_excl_vat' => $extracted[ 'subtotal_excl_vat' ] ?? 0,
            'vat_amount' => $extracted[ 'vat_amount' ] ?? 0,
            'total_incl_vat' => $extracted[ 'total_incl_vat' ] ?? 0,
            'status' => 'pending_review',
            'ocr_confidence' => 50,
        ] );

        return response()->json( [
            'success' => true,
            'message' => 'OCR completed. Please review extracted fields.',
            'receipt' => $purchaseReceipt->fresh( 'lines' ),
        ] );
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Purchase Receipt
    |--------------------------------------------------------------------------
    */

    public function destroy( PurchaseReceipt $purchaseReceipt ) {
        if ( $purchaseReceipt->document_path ) {
            Storage::disk( 'public' )->delete(
                $purchaseReceipt->document_path
            );
        }

        $purchaseReceipt->delete();

        return response()->json( [
            'success' => true,
            'message' => 'Purchase receipt deleted successfully',
        ] );
    }

    /*
    |--------------------------------------------------------------------------
    | Extract Purchase Fields From OCR Text
    |--------------------------------------------------------------------------
    | Basic regex extraction for Mauritian purchase invoices.
    */

    private function extractPurchaseFieldsFromText( string $text ): array {
        $cleanText = preg_replace( '/\s+/', ' ', $text );

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

        $lines = preg_split( '/\r\n|\r|\n/', trim( $text ) );

        if ( !empty( $lines[ 0 ] ) ) {
            $data[ 'supplier_name' ] = trim( $lines[ 0 ] );
        }

        /*
        |--------------------------------------------------------------------------
        | BRN
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/BRN[:\s]*([A-Z0-9]+)/i', $cleanText, $match ) ) {
            $data[ 'supplier_brn' ] = $match[ 1 ];
        }

        /*
        |--------------------------------------------------------------------------
        | VAT Number
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/VAT(?:\s*No\.?|\s*Number)?[:\s]*([A-Z0-9]+)/i', $cleanText, $match ) ) {
            $data[ 'supplier_vat_number' ] = $match[ 1 ];
        }

        /*
        |--------------------------------------------------------------------------
        | Invoice Number
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/(?:Invoice|Inv)\s*(?:No\.?|Number)?[:\s#-]*([A-Z0-9\-\/]+)/i', $cleanText, $match ) ) {
            $data[ 'invoice_number' ] = $match[ 1 ];
        }

        /*
        |--------------------------------------------------------------------------
        | Date
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/(\d{2}[\/\-]\d{2}[\/\-]\d{4})/', $cleanText, $match ) ) {
            $parts = preg_split( '/[\/\-]/', $match[ 1 ] );

            if ( count( $parts ) === 3 ) {
                $data[ 'invoice_date' ] = $parts[ 2 ] . '-' . $parts[ 1 ] . '-' . $parts[ 0 ];
            }
        }

        /*
        |--------------------------------------------------------------------------
        | VAT Amount
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/VAT[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match ) ) {
            $data[ 'vat_amount' ] = ( float ) str_replace( ',', '', $match[ 1 ] );
        }

        /*
        |--------------------------------------------------------------------------
        | Total Incl VAT
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/(?:Total|Amount Due|Grand Total)[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match ) ) {
            $data[ 'total_incl_vat' ] = ( float ) str_replace( ',', '', $match[ 1 ] );
        }

        /*
        |--------------------------------------------------------------------------
        | Subtotal Excl VAT
        |--------------------------------------------------------------------------
        */

        if ( preg_match( '/(?:Subtotal|Sub Total|Total Excl\.? VAT|Excl\.? VAT)[^0-9]*(\d+[,.]?\d*)/i', $cleanText, $match ) ) {
            $data[ 'subtotal_excl_vat' ] = ( float ) str_replace( ',', '', $match[ 1 ] );
        } elseif ( $data[ 'total_incl_vat' ] > 0 && $data[ 'vat_amount' ] > 0 ) {
            $data[ 'subtotal_excl_vat' ] =
            $data[ 'total_incl_vat' ] - $data[ 'vat_amount' ];
        }

        return $data;
    }

    /*
    |--------------------------------------------------------------------------
    | Update Reviewed Purchase Receipt
    |--------------------------------------------------------------------------
    | Used after OCR/manual review.
    */

    public function update( Request $request, PurchaseReceipt $purchaseReceipt ) {
        $validated = $request->validate( [
            'supplier_name' => [ 'nullable', 'string', 'max:255' ],
            'supplier_brn' => [ 'nullable', 'string', 'max:255' ],
            'supplier_vat_number' => [ 'nullable', 'string', 'max:255' ],
            'invoice_number' => [ 'nullable', 'string', 'max:255' ],
            'invoice_date' => [ 'nullable', 'date' ],
            'subtotal_excl_vat' => [ 'nullable', 'numeric' ],
            'vat_amount' => [ 'nullable', 'numeric' ],
            'total_incl_vat' => [ 'nullable', 'numeric' ],
            'status' => [ 'nullable', 'string', 'max:100' ],
        ] );

        $purchaseReceipt->update( $validated );

        return response()->json( [
            'success' => true,
            'message' => 'Purchase receipt updated successfully',
            'receipt' => $purchaseReceipt->fresh( 'lines' ),
        ] );
    }
}