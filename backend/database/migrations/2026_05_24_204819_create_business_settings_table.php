<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Run Migrations
    |--------------------------------------------------------------------------
    */

    public function up(): void
    {
        Schema::create('business_settings', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Business Information
            |--------------------------------------------------------------------------
            */

            $table->string('company_name')->nullable();

            $table->string('brn')->nullable();

            $table->string('vat_number')->nullable();

            $table->text('address')->nullable();

            $table->string('phone')->nullable();

            $table->string('email')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Branding
            |--------------------------------------------------------------------------
            */

            $table->string('logo_path')->nullable();

            $table->text('receipt_footer')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Printing
            |--------------------------------------------------------------------------
            */

            $table->string('default_print_format')
                ->default('thermal');

            /*
            |--------------------------------------------------------------------------
            | MRA e-Invoicing
            |--------------------------------------------------------------------------
            */

            $table->boolean('mra_enabled')
                ->default(false);

            $table->string('mra_environment')
                ->default('TEST');

            $table->string('mra_username')
                ->nullable();

            $table->string('mra_password')
                ->nullable();

            $table->string('mra_api_key')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Timestamps
            |--------------------------------------------------------------------------
            */

            $table->timestamps();
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Reverse Migrations
    |--------------------------------------------------------------------------
    */

    public function down(): void
    {
        Schema::dropIfExists('business_settings');
    }
};