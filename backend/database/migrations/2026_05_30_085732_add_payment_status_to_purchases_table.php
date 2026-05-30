<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::table('purchases', function (Blueprint $table) {

        /*
        |--------------------------------------------------------------------------
        | Supplier Payment Tracking
        |--------------------------------------------------------------------------
        */

        $table->string('payment_status')
            ->default('paid')
            ->after('total_amount');

        $table->decimal('paid_amount', 15, 2)
            ->default(0)
            ->after('payment_status');

        $table->decimal('balance_amount', 15, 2)
            ->default(0)
            ->after('paid_amount');

        $table->timestamp('paid_at')
            ->nullable()
            ->after('balance_amount');
    });
}

public function down(): void
{
    Schema::table('purchases', function (Blueprint $table) {
        $table->dropColumn([
            'payment_status',
            'paid_amount',
            'balance_amount',
            'paid_at',
        ]);
    });
}
};
