<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ingredient extends Model
{
    protected $fillable = [
        'name',
        'unit',
        'stock_quantity',
        'minimum_stock_level',
        'cost_price',
        'is_active',
    ];

    /*
    |--------------------------------------------------------------------------
    | Product Recipes
    |--------------------------------------------------------------------------
    | Shows which products use this ingredient.
    */

    public function productRecipes()
    {
        return $this->hasMany(ProductRecipe::class);
    }
}
