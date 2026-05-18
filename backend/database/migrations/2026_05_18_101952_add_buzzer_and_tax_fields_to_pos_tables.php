<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Buzzer And Product Tax Fields
    |--------------------------------------------------------------------------
    */
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('restaurant_orders', 'buzzer_number')) {
                $table->string('buzzer_number')
                    ->nullable()
                    ->after('order_number');
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'vat_type')) {
                $table->string('vat_type')
                    ->default('taxable')
                    ->after('vat_applicable');
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
            if (Schema::hasColumn('restaurant_orders', 'buzzer_number')) {
                $table->dropColumn('buzzer_number');
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'vat_type')) {
                $table->dropColumn('vat_type');
            }
        });
    }
};
