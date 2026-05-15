<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RestaurantTable;

class RestaurantTableController extends Controller
{
    public function index()
    {
        return RestaurantTable::orderBy('table_name')->get();
    }

    public function show(RestaurantTable $restaurantTable)
    {
        return $restaurantTable;
    }
}