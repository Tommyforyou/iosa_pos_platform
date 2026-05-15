<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();

            $table->foreignId('business_id')->nullable()->constrained('businesses')->nullOnDelete();
            $table->foreignId('product_category_id')->nullable()->constrained('product_categories')->nullOnDelete();

            $table->string('name');
            $table->string('sku')->nullable();
            $table->string('barcode')->nullable();

            $table->string('product_type')->default('standard');
            // standard, food, drink, service, hardware, weighed_item

            $table->decimal('cost_price', 12, 2)->default(0);
            $table->decimal('selling_price', 12, 2)->default(0);

            $table->boolean('vat_applicable')->default(true);
            $table->decimal('vat_rate', 5, 2)->default(15.00);

            $table->decimal('stock_quantity', 12, 3)->default(0);
            $table->decimal('reorder_level', 12, 3)->default(0);

            $table->string('unit')->default('pcs');
            // pcs, kg, litre, metre, box, plate, glass

            $table->boolean('is_active')->default(true);
            $table->text('description')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
