<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Create Ingredients Table
    |--------------------------------------------------------------------------
    | Stores raw inventory ingredients used in recipes/BOM.
    */
    public function up(): void
    {
        Schema::create('ingredients', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Ingredient Information
            |--------------------------------------------------------------------------
            */

            $table->string('name');

            $table->string('unit');
            // kg, litre, gram, piece, bottle, etc.

            /*
            |--------------------------------------------------------------------------
            | Inventory
            |--------------------------------------------------------------------------
            */

            $table->decimal('stock_quantity', 12, 3)
                ->default(0);

            $table->decimal('minimum_stock_level', 12, 3)
                ->default(0);

            /*
            |--------------------------------------------------------------------------
            | Costing
            |--------------------------------------------------------------------------
            */

            $table->decimal('cost_price', 12, 2)
                ->default(0);

            /*
            |--------------------------------------------------------------------------
            | Status
            |--------------------------------------------------------------------------
            */

            $table->boolean('is_active')
                ->default(true);

            $table->timestamps();
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback
    |--------------------------------------------------------------------------
    */
    public function down(): void
    {
        Schema::dropIfExists('ingredients');
    }
};
