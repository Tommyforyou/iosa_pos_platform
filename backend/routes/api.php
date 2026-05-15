<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ProductCategoryController;
use App\Http\Controllers\Api\RestaurantTableController;





Route::apiResource('restaurant-tables', RestaurantTableController::class)->only(['index', 'show']);

Route::apiResource('categories', ProductCategoryController::class)->only(['index', 'show']);

Route::apiResource('products', ProductController::class)->only(['index', 'show']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
