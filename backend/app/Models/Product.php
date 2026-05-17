<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    protected $fillable = [
        'business_id',
        'product_category_id',
        'name',
        'sku',
        'barcode',
        'product_type',
        'cost_price',
        'selling_price',
        'vat_applicable',
        'vat_rate',
        'stock_quantity',
        'reorder_level',
        'unit',
        'is_active',
        'description',
        'image_path',
    ];

    protected $appends = [
        'image_url',
    ];

    protected $casts = [
        'cost_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'stock_quantity' => 'decimal:3',
        'reorder_level' => 'decimal:3',
        'vat_rate' => 'decimal:2',
        'vat_applicable' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ProductCategory::class, 'product_category_id');
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class);
    }

    public function saleItems(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    public function restaurantOrderItems(): HasMany
    {
        return $this->hasMany(RestaurantOrderItem::class);
    }

    /*
    |--------------------------------------------------------------------------
    | Product Recipes
    |--------------------------------------------------------------------------
    | Defines which raw ingredients are consumed when this product is sold.
    */

    public function recipes()
    {
        return $this->hasMany(ProductRecipe::class);
    }

    /*
    |--------------------------------------------------------------------------
    | Product Image URL
    |--------------------------------------------------------------------------
    */

    public function getImageUrlAttribute()
    {
        if (!$this->image_path) {
            return null;
        }

        return asset('storage/' . $this->image_path);
    }

}