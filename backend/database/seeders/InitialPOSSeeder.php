<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Business;
use App\Models\Role;
use App\Models\ProductCategory;
use App\Models\Product;
use App\Models\RestaurantTable;

class InitialPOSSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Create Business
        |--------------------------------------------------------------------------
        */

        $business = Business::create([
            'name' => 'IOSA Restaurant POS Demo',
            'business_type' => 'restaurant',
            'phone' => '2300000000',
            'email' => 'info@iosa.mu',
            'vat_enabled' => true,
            'vat_rate' => 15,
            'currency' => 'MUR',
        ]);

        /*
        |--------------------------------------------------------------------------
        | Roles
        |--------------------------------------------------------------------------
        */

        $roles = [
            'admin',
            'manager',
            'cashier',
            'waiter',
            'kitchen',
            'stock_user',
        ];

        foreach ($roles as $role) {
            Role::create([
                'name' => $role,
                'display_name' => ucfirst($role),
            ]);
        }

        /*
        |--------------------------------------------------------------------------
        | Categories
        |--------------------------------------------------------------------------
        */

        $foodCategory = ProductCategory::create([
            'business_id' => $business->id,
            'name' => 'Food',
            'type' => 'food',
        ]);

        $drinkCategory = ProductCategory::create([
            'business_id' => $business->id,
            'name' => 'Drinks',
            'type' => 'drink',
        ]);

        /*
        |--------------------------------------------------------------------------
        | Products
        |--------------------------------------------------------------------------
        */

        Product::create([
            'business_id' => $business->id,
            'product_category_id' => $foodCategory->id,
            'name' => 'Chicken Fried Rice',
            'product_type' => 'food',
            'selling_price' => 180,
            'stock_quantity' => 100,
            'unit' => 'plate',
        ]);

        Product::create([
            'business_id' => $business->id,
            'product_category_id' => $foodCategory->id,
            'name' => 'Burger Special',
            'product_type' => 'food',
            'selling_price' => 220,
            'stock_quantity' => 100,
            'unit' => 'pcs',
        ]);

        Product::create([
            'business_id' => $business->id,
            'product_category_id' => $drinkCategory->id,
            'name' => 'Coca Cola',
            'product_type' => 'drink',
            'selling_price' => 75,
            'stock_quantity' => 200,
            'unit' => 'glass',
        ]);

        /*
        |--------------------------------------------------------------------------
        | Restaurant Tables
        |--------------------------------------------------------------------------
        */

        for ($i = 1; $i <= 10; $i++) {
            RestaurantTable::create([
                'business_id' => $business->id,
                'table_name' => 'Table ' . $i,
                'capacity' => 4,
                'status' => 'available',
            ]);
        }
    }
}
