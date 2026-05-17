<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /*
    |--------------------------------------------------------------------------
    | Add Void Tracking Fields
    |--------------------------------------------------------------------------
    | Used for cashier dispute handling and audit tracking.
    */
    public function up(): void
    {
        Schema::table(
            'restaurant_order_items',
            function (Blueprint $table) {

                /*
                |--------------------------------------------------------------------------
                | Void Information
                |--------------------------------------------------------------------------
                */

                $table->boolean('is_voided')
                    ->default(false);

                $table->text('void_reason')
                    ->nullable();

                $table->timestamp('voided_at')
                    ->nullable();

                /*
                |--------------------------------------------------------------------------
                | Future Expansion
                |--------------------------------------------------------------------------
                | Later we can add:
                | - voided_by
                | - manager_approved_by
                */
            }
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Rollback
    |--------------------------------------------------------------------------
    */
    public function down(): void
    {
        Schema::table(
            'restaurant_order_items',
            function (Blueprint $table) {

                $table->dropColumn([
                    'is_voided',
                    'void_reason',
                    'voided_at',
                ]);
            }
        );
    }
};