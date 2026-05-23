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
            if (!Schema::hasColumn('restaurant_orders', 'payment_status')) {
                $table->string('payment_status')->default('unpaid');
            }
             if (!Schema::hasColumn('restaurant_orders', 'payment_method')) {
                $table->string('payment_method')->nullable();
            }

            if (!Schema::hasColumn('restaurant_orders', 'subtotal')) {
                $table->decimal('subtotal', 15, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'tax_amount')) {
                $table->decimal('tax_amount', 15, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'discount_amount')) {
                $table->decimal('discount_amount', 15, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'total_amount')) {
                $table->decimal('total_amount', 15, 2)->default(0);
            }
                
            if (!Schema::hasColumn('restaurant_orders', 'paid_at')) {
                 $table->timestamp('paid_at')->nullable();
            }
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