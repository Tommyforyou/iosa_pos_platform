<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Purchase Receipt OCR Tables
    |--------------------------------------------------------------------------
    */

    public function up(): void
    {
        Schema::create('purchase_receipts', function (Blueprint $table) {
            $table->id();

            $table->foreignId('business_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();

            $table->string('supplier_name')->nullable();
            $table->string('supplier_brn')->nullable();
            $table->string('supplier_vat_number')->nullable();

            $table->string('invoice_number')->nullable();
            $table->date('invoice_date')->nullable();

            $table->decimal('subtotal_excl_vat', 15, 2)->default(0);
            $table->decimal('vat_amount', 15, 2)->default(0);
            $table->decimal('total_incl_vat', 15, 2)->default(0);

            $table->string('document_path')->nullable();

            $table->text('ocr_raw_text')->nullable();
            $table->json('ocr_extracted_data')->nullable();

            $table->string('status')->default('pending_review');
            $table->decimal('ocr_confidence', 5, 2)->nullable();

            $table->timestamps();
        });

        Schema::create('purchase_receipt_lines', function (Blueprint $table) {
            $table->id();

            $table->foreignId('purchase_receipt_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->string('description')->nullable();
            $table->decimal('quantity', 15, 3)->default(1);
            $table->decimal('unit_price', 15, 2)->default(0);
            $table->decimal('line_total', 15, 2)->default(0);

            $table->timestamps();
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback
    |--------------------------------------------------------------------------
    */

    public function down(): void
    {
        Schema::dropIfExists('purchase_receipt_lines');
        Schema::dropIfExists('purchase_receipts');
    }
};
