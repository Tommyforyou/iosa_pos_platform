<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Payment Columns
    |--------------------------------------------------------------------------
    | These columns support the cashier payment workflow.
    */
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            $table->string('payment_status')->default('unpaid');
            $table->string('payment_method')->nullable();
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('tax_amount', 12, 2)->default(0);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('total_amount', 12, 2)->default(0);
            $table->timestamp('paid_at')->nullable();
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback Payment Columns
    |--------------------------------------------------------------------------
    */
    public function down(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            $table->dropColumn([
                'payment_status',
                'payment_method',
                'subtotal',
                'tax_amount',
                'discount_amount',
                'total_amount',
                'paid_at',
            ]);
        });
    }
};