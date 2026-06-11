<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
|--------------------------------------------------------------------------
| Create Product Batches Table
|--------------------------------------------------------------------------
| Stores pharmacy batch-level stock information.
|
| Each product can have multiple batches with different:
| - Batch numbers
| - Expiry dates
| - Quantities
| - Cost prices
| - Selling prices
|--------------------------------------------------------------------------
*/

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Run Migration
    |--------------------------------------------------------------------------
    */

    public function up(): void
    {
        Schema::create('product_batches', function (Blueprint $table) {
            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Product Relationship
            |--------------------------------------------------------------------------
            */

            $table->foreignId('product_id')
                ->constrained()
                ->cascadeOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Batch Information
            |--------------------------------------------------------------------------
            */

            $table->string('batch_number');
            $table->date('expiry_date')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Batch Stock And Pricing
            |--------------------------------------------------------------------------
            */

            $table->decimal('quantity', 12, 2)->default(0);
            $table->decimal('cost_price', 12, 2)->default(0);
            $table->decimal('selling_price', 12, 2)->default(0);

            /*
            |--------------------------------------------------------------------------
            | Timestamps
            |--------------------------------------------------------------------------
            */

            $table->timestamps();

            /*
            |--------------------------------------------------------------------------
            | Unique Batch Per Product
            |--------------------------------------------------------------------------
            */

            $table->unique([
                'product_id',
                'batch_number',
            ]);
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Reverse Migration
    |--------------------------------------------------------------------------
    */

    public function down(): void
    {
        Schema::dropIfExists('product_batches');
    }
};
