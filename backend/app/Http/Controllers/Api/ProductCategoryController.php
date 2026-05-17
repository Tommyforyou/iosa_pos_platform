<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductCategory;
use Illuminate\Http\Request;

class ProductCategoryController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Category List
    |--------------------------------------------------------------------------
    */

    public function index()
    {
        return ProductCategory::with('products')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Single Category
    |--------------------------------------------------------------------------
    */

    public function show(ProductCategory $productCategory)
    {
        return $productCategory->load('products');
    }

    /*
    |--------------------------------------------------------------------------
    | Upload Category Image
    |--------------------------------------------------------------------------
    | Stores uploaded category image and saves image path in database.
    */

    public function uploadImage(Request $request, ProductCategory $category)
    {
        $request->validate([
            'image' => ['required', 'image', 'max:2048'],
        ]);

        $path = $request->file('image')
            ->store('categories', 'public');

        $category->update([
            'image_path' => $path,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Category image uploaded successfully',
            'image_url' => asset('storage/' . $path),
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Store Category
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $category = ProductCategory::create([
            'name' => $validated['name'],
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Category created successfully',
            'category' => $category,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Update Category
    |--------------------------------------------------------------------------
    */

    public function update(Request $request, ProductCategory $category)
     {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $category->update([
            'name' => $validated['name'],
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Category updated successfully',
            'category' => $category,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Category
    |--------------------------------------------------------------------------
    */

    public function destroy(ProductCategory $category)
    {
        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Category deleted successfully',
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Active Categories
    |--------------------------------------------------------------------------
    | Used by POS ordering screens.
    | Back Office uses index() to show all categories.
    */

    public function activeCategories()
    {
        return ProductCategory::with([
                'products' => function ($query) {
                    $query->where('is_active', true);
                },
            ])
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }


}