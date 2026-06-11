<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
|--------------------------------------------------------------------------
| Add Pharmacy Fields To Products Table
|--------------------------------------------------------------------------
| Adds medicine-specific fields to the existing products table.
|
| These fields allow IOSA POS to support pharmacy products without creating
| a separate product table.
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
        Schema::table('products', function (Blueprint $table) {
            /*
            |--------------------------------------------------------------------------
            | Pharmacy Product Information
            |--------------------------------------------------------------------------
            */

            $table->string('generic_name')->nullable()->after('name');
            $table->string('brand_name')->nullable()->after('generic_name');
            $table->string('strength')->nullable()->after('brand_name');
            $table->string('dosage_form')->nullable()->after('strength');
            $table->string('manufacturer')->nullable()->after('dosage_form');

            /*
            |--------------------------------------------------------------------------
            | Pharmacy Control Flags
            |--------------------------------------------------------------------------
            */

            $table->boolean('requires_prescription')
                ->default(false)
                ->after('manufacturer');

            $table->boolean('controlled_drug')
                ->default(false)
                ->after('requires_prescription');

            /*
            |--------------------------------------------------------------------------
            | Pharmacy Stock Control
            |--------------------------------------------------------------------------
            */

            $table->integer('minimum_stock')
                ->default(0)
                ->after('controlled_drug');
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Reverse Migration
    |--------------------------------------------------------------------------
    */

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'generic_name',
                'brand_name',
                'strength',
                'dosage_form',
                'manufacturer',
                'requires_prescription',
                'controlled_drug',
                'minimum_stock',
            ]);
        });
    }
};
