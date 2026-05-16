<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Missing Payment Columns
    |--------------------------------------------------------------------------
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
                $table->decimal('subtotal', 12, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'tax_amount')) {
                $table->decimal('tax_amount', 12, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'discount_amount')) {
                $table->decimal('discount_amount', 12, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'total_amount')) {
                $table->decimal('total_amount', 12, 2)->default(0);
            }

            if (!Schema::hasColumn('restaurant_orders', 'paid_at')) {
                $table->timestamp('paid_at')->nullable();
            }
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback
    |--------------------------------------------------------------------------
    */
    public function down(): void
    {
        //
    }
};