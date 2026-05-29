<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
public function up(): void
{
    Schema::create('customer_payments', function (Blueprint $table) {
        $table->id();

        /*
        |--------------------------------------------------------------------------
        | Customer Payment Details
        |--------------------------------------------------------------------------
        */

        $table->foreignId('customer_id')
            ->constrained()
            ->cascadeOnDelete();

        $table->decimal('amount', 15, 2);

        $table->string('payment_method')
            ->default('cash');

        $table->string('reference')
            ->nullable();

        $table->text('notes')
            ->nullable();

        $table->date('payment_date');

        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('customer_payments');
}
};
