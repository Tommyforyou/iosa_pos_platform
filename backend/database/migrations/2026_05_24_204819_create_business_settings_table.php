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
Schema::create('business_settings', function (Blueprint $table) {

    $table->id();

    $table->string('company_name')->nullable();

    $table->string('brn')->nullable();

    $table->string('vat_number')->nullable();

    $table->text('address')->nullable();

    $table->string('phone')->nullable();

    $table->string('email')->nullable();

    $table->string('logo_path')->nullable();

    $table->text('receipt_footer')->nullable();

    $table->string('default_print_format')
        ->default('thermal');

    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('business_settings');
    }
};
