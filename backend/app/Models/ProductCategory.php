<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductCategory extends Model
{
    protected $fillable = [
        'business_id',
        'name',
        'type',
        'description',
        'is_active',
        'sort_order',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /*
    |--------------------------------------------------------------------------
    | Upload Category Image
    |--------------------------------------------------------------------------
    | Uploads and stores category image for POS display.
    */
    public function uploadImage(Request $request, ProductCategory $category)
    {
        $validated = $request->validate([
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
}
