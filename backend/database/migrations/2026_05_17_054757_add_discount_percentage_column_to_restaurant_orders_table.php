<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Discount Percentage Column
    |--------------------------------------------------------------------------
    | Stores the selected discount percentage applied during billing/counter POS.
    */
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('restaurant_orders', 'discount_percentage')) {
                $table->decimal('discount_percentage', 5, 2)->default(0);
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
        Schema::table('restaurant_orders', function (Blueprint $table) {
            if (Schema::hasColumn('restaurant_orders', 'discount_percentage')) {
                $table->dropColumn('discount_percentage');
            }
        });
    }
};