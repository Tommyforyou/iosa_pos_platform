<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;


class ProductController extends Controller
{
    public function index()
    {
        return Product::with('category')
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    public function show(Product $product)
    {
        return $product->load('category');
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
}