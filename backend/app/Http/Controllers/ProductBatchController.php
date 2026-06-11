<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\ProductBatch;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| Product Batch Controller
|--------------------------------------------------------------------------
| Handles pharmacy batch management.
|
| Responsibilities:
| - List product batches
| - Create product batch
| - Update product batch
| - Delete product batch
|--------------------------------------------------------------------------
*/

class ProductBatchController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | List Batches
    |--------------------------------------------------------------------------
    */

    public function index()
    {
        return ProductBatch::with('product')
            ->latest()
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Store Batch
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'product_id' => ['required', 'exists:products,id'],
            'batch_number' => ['required', 'string', 'max:255'],
            'expiry_date' => ['nullable', 'date'],
            'quantity' => ['required', 'numeric', 'min:0'],
            'cost_price' => ['required', 'numeric', 'min:0'],
            'selling_price' => ['required', 'numeric', 'min:0'],
        ]);

        $batch = ProductBatch::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product batch created successfully.',
            'batch' => $batch->load('product'),
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Update Batch
    |--------------------------------------------------------------------------
    */

    public function update(Request $request, ProductBatch $productBatch)
    {
        $validated = $request->validate([
            'product_id' => ['required', 'exists:products,id'],
            'batch_number' => ['required', 'string', 'max:255'],
            'expiry_date' => ['nullable', 'date'],
            'quantity' => ['required', 'numeric', 'min:0'],
            'cost_price' => ['required', 'numeric', 'min:0'],
            'selling_price' => ['required', 'numeric', 'min:0'],
        ]);

        $productBatch->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product batch updated successfully.',
            'batch' => $productBatch->load('product'),
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Batch
    |--------------------------------------------------------------------------
    */

    public function destroy(ProductBatch $productBatch)
    {
        $productBatch->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product batch deleted successfully.',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Product Batches
    |--------------------------------------------------------------------------
    | Returns all batches for one product.
    |--------------------------------------------------------------------------
    */

    public function byProduct(Product $product)
    {
        return $product->batches()
            ->latest()
            ->get();
    }
}
