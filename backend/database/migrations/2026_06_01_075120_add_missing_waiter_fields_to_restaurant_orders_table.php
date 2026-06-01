<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
|--------------------------------------------------------------------------
| Add Missing Waiter Fields To Restaurant Orders Table
|--------------------------------------------------------------------------
*/

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            /*
            |--------------------------------------------------------------------------
            | Waiter Tracking
            |--------------------------------------------------------------------------
            */

            if (!Schema::hasColumn('restaurant_orders', 'waiter_id')) {
                $table->foreignId('waiter_id')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete();
            }

            /*
            |--------------------------------------------------------------------------
            | Bill Request Tracking
            |--------------------------------------------------------------------------
            */

            if (!Schema::hasColumn('restaurant_orders', 'bill_requested_at')) {
                $table->timestamp('bill_requested_at')->nullable();
            }

            if (!Schema::hasColumn('restaurant_orders', 'bill_requested_by')) {
                $table->foreignId('bill_requested_by')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('restaurant_orders', function (Blueprint $table) {
            if (Schema::hasColumn('restaurant_orders', 'waiter_id')) {
                $table->dropConstrainedForeignId('waiter_id');
            }

            if (Schema::hasColumn('restaurant_orders', 'bill_requested_at')) {
                $table->dropColumn('bill_requested_at');
            }

            if (Schema::hasColumn('restaurant_orders', 'bill_requested_by')) {
                $table->dropConstrainedForeignId('bill_requested_by');
            }
        });
    }
};