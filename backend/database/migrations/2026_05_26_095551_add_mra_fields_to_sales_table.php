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
        Schema::table('sales', function (Blueprint $table) {
/*
        |--------------------------------------------------------------------------
        | MRA e-Invoicing Fields
        |--------------------------------------------------------------------------
        */

        $table->boolean('mra_submitted')
            ->default(false);

        $table->string('mra_irn')
            ->nullable();

        $table->longText('mra_qr_code')
            ->nullable();

        $table->string('mra_status')
            ->nullable();

        $table->timestamp('mra_submitted_at')
            ->nullable();

        $table->json('mra_response')
            ->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
 $table->dropColumn([
            'mra_submitted',
            'mra_irn',
            'mra_qr_code',
            'mra_status',
            'mra_submitted_at',
            'mra_response',
        ]);

        });
    }
};
