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
Schema::create('printers', function (Blueprint $table) {
    $table->id();

    $table->string('name');
    $table->string('ip_address');
    $table->integer('port')->default(9100);

    $table->enum('location', [
        'kitchen',
        'bar',
        'cashier'
    ]);

    $table->boolean('auto_print')->default(true);

    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('printers');
    }
};
