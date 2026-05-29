<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuickSaleVoidController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Void Quick Sale
    |--------------------------------------------------------------------------
    */

    public function void(Request $request, Sale $sale)
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);


        if ($sale->sale_status === 'voided') {
            return response()->json([
                'success' => false,
                'message' => 'This sale has already been voided.',
            ], 422);
        }


        /*
        |--------------------------------------------------------------------------
        | Prevent Voiding Fiscalised Invoices
        |--------------------------------------------------------------------------
        */

        if ($sale->mra_submitted) {
            return response()->json([
                'success' => false,
                'message' => 'Fiscalised invoices cannot be voided. Please issue a Credit Note.',
            ], 422);
        }



        return DB::transaction(function () use ($sale, $validated) {
            $sale->load('items');

            foreach ($sale->items as $item) {
                if (!$item->product_id) {
                    continue;
                }

                $product = Product::find($item->product_id);

                if (!$product) {
                    continue;
                }

                $quantity = (float) $item->quantity;

                $beforeQuantity = (float) ($product->stock_quantity ?? 0);
                $afterQuantity = $beforeQuantity + $quantity;

                $product->update([
                    'stock_quantity' => $afterQuantity,
                ]);

                StockMovement::create([
                    'product_id' => $product->id,
                    'user_id' => auth()->id(),
                    'movement_type' => 'void',
                    'quantity' => abs($quantity),
                    'before_quantity' => $beforeQuantity,
                    'after_quantity' => $afterQuantity,
                    'remarks' => 'Void quick sale - ' . $sale->invoice_number,
                ]);
            }

            $sale->update([
                'sale_status' => 'voided',
                'payment_status' => 'voided',
                'notes' => $validated['reason'],
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Sale voided successfully.',
                'sale' => $sale->fresh(['customer', 'items']),
            ]);
        });
    }
}