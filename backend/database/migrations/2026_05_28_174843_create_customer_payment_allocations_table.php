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
       Schema::create('customer_payment_allocations', function (Blueprint $table) {
        $table->id();

        /*
        |--------------------------------------------------------------------------
        | Allocation Links
        |--------------------------------------------------------------------------
        */

        $table->foreignId('customer_payment_id')
            ->constrained()
            ->cascadeOnDelete();

        $table->foreignId('sale_id')
            ->constrained()
            ->cascadeOnDelete();

        /*
        |--------------------------------------------------------------------------
        | Allocated Amount
        |--------------------------------------------------------------------------
        */

        $table->decimal('amount', 15, 2);

        $table->timestamps();
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customer_payment_allocations');
    }
};
