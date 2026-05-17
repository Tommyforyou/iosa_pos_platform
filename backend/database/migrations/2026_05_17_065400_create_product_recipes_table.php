<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Create Product Recipes Table
    |--------------------------------------------------------------------------
    | Defines ingredient usage per product.
    |
    | Example:
    | Chicken Fried Rice
    | → Rice 0.250 kg
    | → Chicken 0.150 kg
    | → Oil 0.020 litre
    */
    public function up(): void
    {
        Schema::create('product_recipes', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Product
            |--------------------------------------------------------------------------
            */

            $table->foreignId('product_id')
                ->constrained()
                ->cascadeOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Ingredient
            |--------------------------------------------------------------------------
            */

            $table->foreignId('ingredient_id')
                ->constrained()
                ->cascadeOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Quantity Used Per Product Sale
            |--------------------------------------------------------------------------
            */

            $table->decimal('quantity_required', 12, 3);

            /*
            |--------------------------------------------------------------------------
            | Optional Notes
            |--------------------------------------------------------------------------
            */

            $table->text('notes')
                ->nullable();

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
        Schema::dropIfExists('product_recipes');
    }
};
