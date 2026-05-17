<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Controllers
|--------------------------------------------------------------------------
| These controllers handle all Flutter ↔ Laravel communication
| for the IOSA POS Platform.
*/

use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ProductCategoryController;
use App\Http\Controllers\Api\RestaurantTableController;
use App\Http\Controllers\Api\RestaurantOrderController;

/*
|--------------------------------------------------------------------------
| Restaurant Tables API
|--------------------------------------------------------------------------
| Used by:
| - waiter tablet
| - cashier
| - floor manager
|
| Responsibilities:
| - load restaurant tables
| - view table statuses
|
| Endpoints:
| GET /api/restaurant-tables
| GET /api/restaurant-tables/{id}
*/

Route::apiResource(
    'restaurant-tables',
    RestaurantTableController::class
)->only([
    'index',
    'show',
]);

/*
|--------------------------------------------------------------------------
| Product Categories API
|--------------------------------------------------------------------------
| Used for POS product grouping.
|
| Examples:
| - Burgers
| - Drinks
| - Desserts
|
| Endpoints:
| GET /api/categories
| GET /api/categories/{id}
*/

Route::apiResource(
    'categories',
    ProductCategoryController::class
)->only([
    'index',
    'show',
]);

/*
|--------------------------------------------------------------------------
| Products API
|--------------------------------------------------------------------------
| Used by Flutter POS ordering screens.
|
| Endpoints:
| GET /api/products
| GET /api/products/{id}
*/

Route::apiResource('products', ProductController::class);

/*
|--------------------------------------------------------------------------
| Store Restaurant Order
|--------------------------------------------------------------------------
| Saves:
| - dine-in orders
| - takeaway orders
| - delivery orders
|
| Called when waiter/cashier clicks:
| "Send to Kitchen"
*/

Route::post(
    'restaurant-orders',
    [RestaurantOrderController::class, 'store']
);

/*
|--------------------------------------------------------------------------
| Kitchen Orders API
|--------------------------------------------------------------------------
| Returns active orders visible on Kitchen Display System (KDS).
|
| Used by:
| - kitchen monitors
| - kitchen tablets
*/

Route::get(
    'kitchen-orders',
    [RestaurantOrderController::class, 'kitchenOrders']
);

/*
|--------------------------------------------------------------------------
| Active Table Order API
|--------------------------------------------------------------------------
| Used when waiter reopens occupied dine-in table.
|
| Returns:
| - active order
| - existing items
*/

Route::get(
    'restaurant-tables/{tableId}/active-order',
    [RestaurantOrderController::class, 'activeOrderByTable']
);

/*
|--------------------------------------------------------------------------
| Kitchen Item Status API
|--------------------------------------------------------------------------
| Updates kitchen workflow statuses:
|
| pending
| preparing
| ready
| served
| cancelled
*/

Route::patch(
    'restaurant-order-items/{itemId}/kitchen-status',
    [RestaurantOrderController::class, 'updateKitchenItemStatus']
);

/*
|--------------------------------------------------------------------------
| Billable Orders API
|--------------------------------------------------------------------------
| Returns active orders for cashier billing screen.
|
| Includes:
| - dine-in
| - takeaway
| - delivery
*/

Route::get(
    'billable-orders',
    [RestaurantOrderController::class, 'billableOrders']
);

/*
|--------------------------------------------------------------------------
| Process Restaurant Payment
|--------------------------------------------------------------------------
| Marks restaurant order as paid.
|
| Responsibilities:
| - save payment details
| - close order
| - release dine-in table
*/

Route::post(
    'restaurant-orders/{orderId}/payment',
    [RestaurantOrderController::class, 'processPayment']
);

/*
|--------------------------------------------------------------------------
| POS Dashboard Statistics
|--------------------------------------------------------------------------
*/

Route::get(
    'dashboard-stats',
    [RestaurantOrderController::class, 'dashboardStats']
);


/*
|--------------------------------------------------------------------------
| Daily Sales Report
|--------------------------------------------------------------------------
*/

Route::get(
    'reports/daily-sales',
    [RestaurantOrderController::class, 'dailySalesReport']
);

/*
|--------------------------------------------------------------------------
| Authenticated User API
|--------------------------------------------------------------------------
| Default Laravel Sanctum authenticated user endpoint.
|
| Future use:
| - POS staff login
| - cashier login
| - kitchen login
| - admin permissions
*/


/*
|--------------------------------------------------------------------------
| Void Restaurant Order Item
|--------------------------------------------------------------------------
*/

Route::patch(
    'restaurant-order-items/{itemId}/void',
    [RestaurantOrderController::class, 'voidOrderItem']
);



/*
|--------------------------------------------------------------------------
| Save Draft Restaurant Order
|--------------------------------------------------------------------------
| Saves order items as draft before sending to kitchen.
*/
Route::post(
    'restaurant-orders/draft',
    [RestaurantOrderController::class, 'saveDraftOrder']
);

/*
|--------------------------------------------------------------------------
| Send Draft Items To Kitchen
|--------------------------------------------------------------------------
*/

Route::patch(
    'restaurant-orders/{orderId}/send-to-kitchen',
    [RestaurantOrderController::class, 'sendDraftItemsToKitchen']
);


/*
|--------------------------------------------------------------------------
| Counter POS Order Payment
|--------------------------------------------------------------------------
| Used for KFC-style fast counter ordering.
*/

Route::post(
    'counter-orders',
    [RestaurantOrderController::class, 'counterOrderPayment']
);


/*
|--------------------------------------------------------------------------
| Product / Category Image Uploads
|--------------------------------------------------------------------------
*/

Route::post(
    'products/{product}/image',
    [ProductController::class, 'uploadImage']
);

Route::post(
    'categories/{category}/image',
    [ProductCategoryController::class, 'uploadImage']
);

/*
|--------------------------------------------------------------------------
| Categories
|--------------------------------------------------------------------------
*/
Route::apiResource('categories',ProductCategoryController::class);

/*
|--------------------------------------------------------------------------
| Active Categories For POS
|--------------------------------------------------------------------------
| Used by ordering screens only.
*/

Route::get(
    'active-categories',
    [ProductCategoryController::class, 'activeCategories']
);








Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
