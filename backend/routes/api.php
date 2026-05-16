<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ProductCategoryController;
use App\Http\Controllers\Api\RestaurantTableController;
use App\Http\Controllers\Api\RestaurantOrderController;





Route::apiResource('restaurant-tables', RestaurantTableController::class)->only(['index', 'show']);
Route::apiResource('categories', ProductCategoryController::class)->only(['index', 'show']);
Route::apiResource('products', ProductController::class)->only(['index', 'show']);
Route::post('restaurant-orders',[RestaurantOrderController::class, 'store']);

Route::get('kitchen-orders', [RestaurantOrderController::class, 'kitchenOrders']);

Route::get('restaurant-tables/{tableId}/active-order',[RestaurantOrderController::class, 'activeOrderByTable']);


Route::get('/user', function (Request $request) {return $request->user();})->middleware('auth:sanctum');
