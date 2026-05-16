<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {

            /*
            |--------------------------------------------------------------------------
            | Payment Information
            |--------------------------------------------------------------------------
            | These fields are used by cashier/payment workflow.
            */

            $table->string('payment_status')
                ->default('unpaid')
                ->after('status');

            $table->string('payment_method')
                ->nullable()
                ->after('payment_status');

            $table->decimal('subtotal', 12, 2)
                ->default(0)
                ->after('payment_method');

            $table->decimal('tax_amount', 12, 2)
                ->default(0)
                ->after('subtotal');

            $table->decimal('discount_amount', 12, 2)
                ->default(0)
                ->after('tax_amount');

            $table->decimal('total_amount', 12, 2)
                ->default(0)
                ->after('discount_amount');

            $table->timestamp('paid_at')
                ->nullable()
                ->after('total_amount');
        });
    }

    /**
     * Reverse the migrations.
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