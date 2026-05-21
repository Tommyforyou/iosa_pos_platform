<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Quick Sales Tables
    |--------------------------------------------------------------------------
    */

public function up(): void
{
    if (!Schema::hasTable('sales')) {
        Schema::create('sales', function (Blueprint $table) {
            $table->id();

            $table->foreignId('business_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();

            $table->foreignId('customer_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();

            $table->string('sale_number')->unique();

            $table->string('sale_type')->default('walk_in');
            $table->string('payment_status')->default('paid');
            $table->string('payment_method')->default('cash');

            $table->decimal('subtotal_excl_vat', 15, 2)->default(0);
            $table->decimal('vat_amount', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('total_incl_vat', 15, 2)->default(0);

            $table->dateTime('sale_date')->nullable();

            $table->timestamps();
        });
    }

    if (!Schema::hasTable('sale_items')) {
        Schema::create('sale_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('sale_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('product_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();

            $table->string('description');
            $table->decimal('quantity', 15, 3)->default(1);
            $table->decimal('unit_price_excl_vat', 15, 2)->default(0);
            $table->decimal('vat_amount', 15, 2)->default(0);
            $table->decimal('line_total_incl_vat', 15, 2)->default(0);

            $table->timestamps();
        });
    }
}

    public function down(): void
    {
        Schema::dropIfExists('sale_items');
        Schema::dropIfExists('sales');
    }
};