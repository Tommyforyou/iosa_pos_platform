<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Image Fields
    |--------------------------------------------------------------------------
    | Stores uploaded image paths for POS display.
    */
    public function up(): void
    {
        Schema::table('product_categories', function (Blueprint $table) {
            $table->string('image_path')->nullable();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->string('image_path')->nullable();
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback
    |--------------------------------------------------------------------------
    */
    public function down(): void
    {
        Schema::table('product_categories', function (Blueprint $table) {
            $table->dropColumn('image_path');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('image_path');
        });
    }
};
