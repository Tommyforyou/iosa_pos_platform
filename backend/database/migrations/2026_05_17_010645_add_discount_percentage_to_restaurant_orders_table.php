<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Discount Percentage
    |--------------------------------------------------------------------------
    */
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {

            $table->decimal(
                'discount_percentage',
                5,
                2
            )->default(0)->after('discount_amount');
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

            $table->dropColumn([
                'discount_percentage',
            ]);
        });
    }
};