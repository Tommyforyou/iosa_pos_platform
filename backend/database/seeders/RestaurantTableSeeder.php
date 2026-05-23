<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\RestaurantTable;

class RestaurantTableSeeder extends Seeder
{
    public function run(): void
    {
        $tables = [

            [
                'table_name' => 'Table 1',
                'capacity' => 2,
                'status' => 'available',
                'is_active' => true,
            ],

            [
                'table_name' => 'Table 2',
                'capacity' => 4,
                'status' => 'available',
                'is_active' => true,
            ],

            [
                'table_name' => 'Table 3',
                'capacity' => 6,
                'status' => 'available',
                'is_active' => true,
            ],

            [
                'table_name' => 'VIP 1',
                'capacity' => 8,
                'status' => 'available',
                'is_active' => true,
            ],

        ];

        foreach ($tables as $table) {

            RestaurantTable::updateOrCreate(
                [
                    'table_name' => $table['table_name'],
                ],
                $table
            );
        }
    }
}