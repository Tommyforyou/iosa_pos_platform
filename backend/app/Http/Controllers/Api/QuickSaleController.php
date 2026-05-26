<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Services\MraService;

class QuickSaleController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Store Quick Sale
    |--------------------------------------------------------------------------
    */

   public function store(Request $request, MraService $mraService)
    {
        $validated = $request->validate([
            'customer_id' => ['nullable', 'exists:customers,id'],
            'sale_type' => ['required', 'in:walk_in,vat_invoice,credit'],
            'payment_method' => ['required', 'in:cash,card,juice,cheque,credit'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['nullable', 'exists:products,id'],
            'items.*.description' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.unit_price_excl_vat' => ['required', 'numeric', 'min:0'],
            'items.*.vat_amount' => ['required', 'numeric', 'min:0'],
            'items.*.line_total_incl_vat' => ['required', 'numeric', 'min:0'],
            'items.*.save_as_product' => ['nullable', 'boolean'],
            'items.*.barcode' => ['nullable', 'string', 'max:255'],
        ]);

        return DB::transaction(function () use ($validated, $mraService) {
                $subtotal = collect($validated['items'])
                    ->sum(function ($item) {
                        return ((float) $item['quantity']) *
                            ((float) $item['unit_price_excl_vat']);
                    });

                $vatAmount = collect($validated['items'])
                    ->sum(function ($item) {
                        return (float) $item['vat_amount'];
                    });

                $total = collect($validated['items'])
                    ->sum(function ($item) {
                        return (float) $item['line_total_incl_vat'];
                    });

            $sale = Sale::create([
                'business_id' => null,
                'customer_id' => $validated['customer_id'] ?? null,
                 'invoice_number' => 'QS-' . now()->format('YmdHis') . '-' . random_int(1000, 9999),
                'sale_type' => $validated['sale_type'],
                'payment_status' => $validated['payment_method'] === 'credit'
                    ? 'unpaid'
                    : 'paid',
                'payment_method' => $validated['payment_method'],
                'subtotal' => $subtotal,
                'vat_amount' => $vatAmount,
                'discount_amount' => 0,
                'total_amount' => $total,
                'sale_date' => now(),
                
            ]);

            foreach ($validated['items'] as $item) {
            $productId = $item['product_id'] ?? null;

                if (
                    empty($productId) &&
                    !empty($item['save_as_product'])
                ) {
                    $product = Product::create([
                        'business_id' => null,
                        'product_category_id' => null,
                        'name' => $item['description'],
                        'selling_price' => $item['unit_price_excl_vat'],
                        'cost_price' => 0,
                        'stock_quantity' => 0,
                        'reorder_level' => 0,
                        'unit' => 'pcs',
                        'vat_applicable' => true,
                        'vat_rate' => 15,
                        'is_active' => true,
                        'barcode' => $item['barcode'] ?? null,
                    ]);

                    $productId = $product->id;
                }    
            
                  $sale->items()->create([
                    'product_id' => $productId,
                    'product_name' => $item['description'],

                    'quantity' => $item['quantity'],

                    'unit_price' => $item['unit_price_excl_vat'],
                    'line_total' => $item['line_total_incl_vat'],

                    'vat_amount' => $item['vat_amount'],
                ]);

                if (!empty($item['product_id'])) {
                    $this->deductProductStock(
                        productId: $item['product_id'],
                        quantity: (float) $item['quantity'],
                        reference: $sale->invoice_number,
                    );
                }
            }

            /*
            |--------------------------------------------------------------------------
            | Optional MRA e-Invoicing Submission
            |--------------------------------------------------------------------------
            | If MRA is enabled in Business Settings, fiscalise the sale before printing.
            */

            $mraResult = null;

            $settings = \App\Models\BusinessSetting::first();

            if ($settings?->mra_enabled) {
                $mraResult = $mraService->submitSale($sale);

                $sale->refresh();
            }             
           
            
            return response()->json([
                'success' => true,
                'message' => 'Quick sale created successfully',
                'sale' => $sale->fresh([
                    'customer',
                    'items',
                ]),
                'mra' => $mraResult,
            ], 201);
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Deduct Product Stock
    |--------------------------------------------------------------------------
    */

    private function deductProductStock(
        int $productId,
        float $quantity,
        string $reference
    ): void {
        $product = Product::find($productId);

        if (!$product) {
            return;
        }

        $beforeQuantity = (float) ($product->stock_quantity ?? 0);
        $afterQuantity = $beforeQuantity - $quantity;

        $product->update([
            'stock_quantity' => $afterQuantity,
        ]);

        StockMovement::create([
            'product_id' => $product->id,
            'user_id' => auth()->id(),
            'movement_type' => 'sale',
            'quantity' => -abs($quantity),
            'before_quantity' => $beforeQuantity,
            'after_quantity' => $afterQuantity,
            'remarks' => 'Quick sale - ' . $reference,
        ]);
    }
}