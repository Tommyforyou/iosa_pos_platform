<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Storage;


class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with('category')
            ->where('is_active', true);

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
               $q->where('name', 'ILIKE', '%' . $request->search . '%')
                ->orWhere('sku', 'ILIKE', '%' . $request->search . '%')
                ->orWhere('barcode', 'ILIKE', '%' . $request->search . '%');
            });
        }

        return $query
            ->orderBy('name')
            ->limit(100)
            ->get();
    }


    /*
    |--------------------------------------------------------------------------
    | Upload Product Image
    |--------------------------------------------------------------------------
    | Uploads and stores product image for POS display.
    */
    public function uploadImage(Request $request, Product $product)
    {
        $validated = $request->validate([
            'image' => ['required', 'image', 'max:2048'],
        ]);

        $path = $request->file('image')
            ->store('products', 'public');

        $product->update([
            'image_path' => $path,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Product image uploaded successfully',
            'image_url' => asset('storage/' . $path),
        ]);
    } 
    
 /*
|--------------------------------------------------------------------------
| Store Product
|--------------------------------------------------------------------------
| Creates a new product/menu item.
*/

public function store(Request $request)
{
    $validated = $request->validate([
        'product_category_id' => ['required', 'exists:product_categories,id'],
        'name' => ['required', 'string', 'max:255'],
        'product_type' => ['nullable', 'string', 'max:50'],
        'cost_price' => ['nullable', 'numeric'],
        'selling_price' => ['required', 'numeric', 'min:0'],
        'vat_applicable' => ['nullable', 'boolean'],
        'vat_rate' => ['nullable', 'numeric'],
        'stock_quantity' => ['nullable', 'numeric'],
        'reorder_level' => ['nullable', 'numeric'],
        'unit' => ['nullable', 'string', 'max:50'],
        'description' => ['nullable', 'string'],
        'is_active' => ['nullable', 'boolean'],
        'barcode' => ['nullable', 'string', 'max:255'],
    ]);

    $product = Product::create([
        'business_id' => 1,
        'product_category_id' => $validated['product_category_id'],
        'name' => $validated['name'],
        'product_type' => $validated['product_type'] ?? 'general',
        'cost_price' => $validated['cost_price'] ?? 0,
        'selling_price' => $validated['selling_price'],
        'vat_applicable' => $validated['vat_applicable'] ?? true,
        'vat_rate' => $validated['vat_rate'] ?? 15,
        'stock_quantity' => $validated['stock_quantity'] ?? 0,
        'reorder_level' => $validated['reorder_level'] ?? 0,
        'unit' => $validated['unit'] ?? 'pcs',
        'description' => $validated['description'] ?? null,
        'is_active' => $validated['is_active'] ?? true,
        'barcode' => $validated['barcode'] ?? null,
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Product created successfully',
        'product' => $product,
    ]);
}

    /*
    |--------------------------------------------------------------------------
    | Update Product
    |--------------------------------------------------------------------------
    | Updates an existing product/menu item.
    */

    public function update(Request $request, Product $product)
    {
        $validated = $request->validate([
            'product_category_id' => ['required', 'exists:product_categories,id'],
            'name' => ['required', 'string', 'max:255'],
            'product_type' => ['nullable', 'string', 'max:50'],
            'cost_price' => ['nullable', 'numeric'],
            'selling_price' => ['required', 'numeric', 'min:0'],
            'vat_applicable' => ['nullable', 'boolean'],
            'vat_rate' => ['nullable', 'numeric'],
            'stock_quantity' => ['nullable', 'numeric'],
            'reorder_level' => ['nullable', 'numeric'],
            'unit' => ['nullable', 'string', 'max:50'],
            'description' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
            'barcode' => ['nullable', 'string', 'max:255'],
        ]);

        $product->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'product' => $product,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Product
    |--------------------------------------------------------------------------
    | Deletes product.
    | Later we may change this to soft delete/inactive for audit safety.
    */

    public function destroy(Product $product)
    {
        $product->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully',
        ]);
    }   


}