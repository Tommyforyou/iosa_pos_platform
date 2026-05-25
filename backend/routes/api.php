<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SupplierController;
use App\Http\Controllers\Api\ZReportController;
use App\Http\Controllers\Api\StockMovementController;
use App\Http\Controllers\Api\QuickSaleController;
use App\Http\Controllers\Api\QuickSaleHistoryController;
use App\Http\Controllers\Api\QuickSaleVoidController;

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
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\PurchaseReceiptController;
use App\Http\Controllers\Api\PurchaseController;

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
| GET /api/restaurant-tables/ {
    id}
    */

    Route::apiResource(
        'restaurant-tables',
        RestaurantTableController::class
    )->only( [
        'index',
        'show',
    ] );

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
    | GET /api/categories/ {
        id}
        */

        Route::apiResource(
            'categories',
            ProductCategoryController::class
        )->only( [
            'index',
            'show',
        ] );

        /*
        |--------------------------------------------------------------------------
        | Products API
        |--------------------------------------------------------------------------
        | Used by Flutter POS ordering screens.
        |
        | Endpoints:
        | GET /api/products
        | GET /api/products/ {
            id}
            */

            Route::apiResource( 'products', ProductController::class );

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
            | 'Send to Kitchen'
            */

            Route::post(
                'restaurant-orders',
                [ RestaurantOrderController::class, 'store' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Kitchen Orders API
            |--------------------------------------------------------------------------
            | Returns active orders visible on Kitchen Display System ( KDS ).
            |
            | Used by:
            | - kitchen monitors
            | - kitchen tablets
            */

            Route::get(
                'kitchen-orders',
                [ RestaurantOrderController::class, 'kitchenOrders' ]
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
                [ RestaurantOrderController::class, 'activeOrderByTable' ]
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
                [ RestaurantOrderController::class, 'updateKitchenItemStatus' ]
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
                [ RestaurantOrderController::class, 'billableOrders' ]
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
                [ RestaurantOrderController::class, 'processPayment' ]
            );

            /*
            |--------------------------------------------------------------------------
            | POS Dashboard Statistics
            |--------------------------------------------------------------------------
            */

            Route::get(
                'dashboard-stats',
                [ RestaurantOrderController::class, 'dashboardStats' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Daily Sales Report
            |--------------------------------------------------------------------------
            */

            Route::get(
                'reports/daily-sales',
                [ RestaurantOrderController::class, 'dailySalesReport' ]
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
                [ RestaurantOrderController::class, 'voidOrderItem' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Save Draft Restaurant Order
            |--------------------------------------------------------------------------
            | Saves order items as draft before sending to kitchen.
            */
            Route::post(
                'restaurant-orders/draft',
                [ RestaurantOrderController::class, 'saveDraftOrder' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Send Draft Items To Kitchen
            |--------------------------------------------------------------------------
            */

            Route::patch(
                'restaurant-orders/{orderId}/send-to-kitchen',
                [ RestaurantOrderController::class, 'sendDraftItemsToKitchen' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Counter POS Order Payment
            |--------------------------------------------------------------------------
            | Used for KFC-style fast counter ordering.
            */

            Route::post(
                'counter-orders',
                [ RestaurantOrderController::class, 'counterOrderPayment' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Product / Category Image Uploads
            |--------------------------------------------------------------------------
            */

            Route::post(
                'products/{product}/image',
                [ ProductController::class, 'uploadImage' ]
            );

            Route::post(
                'categories/{category}/image',
                [ ProductCategoryController::class, 'uploadImage' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Categories
            |--------------------------------------------------------------------------
            */
            Route::apiResource( 'categories', ProductCategoryController::class );

            /*
            |--------------------------------------------------------------------------
            | Active Categories For POS
            |--------------------------------------------------------------------------
            | Used by ordering screens only.
            */

            Route::get(
                'active-categories',
                [ ProductCategoryController::class, 'activeCategories' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Kitchen Display System
            |--------------------------------------------------------------------------
            */

            Route::get(
                'kitchen/orders',
                [ RestaurantOrderController::class, 'kitchenOrders' ]
            );

            Route::post(
                'kitchen/orders/{restaurantOrder}/status',
                [ RestaurantOrderController::class, 'updateKitchenStatus' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Customers
            |--------------------------------------------------------------------------
            */

            Route::get(
                'customers/search-by-phone',
                [ CustomerController::class, 'searchByPhone' ]
            );

            Route::apiResource(
                'customers',
                CustomerController::class
            )->only( [
                'index',
                'store',
                'update',
            ] );

            /*
            |--------------------------------------------------------------------------
            | Purchase Receipt OCR
            |--------------------------------------------------------------------------
            */

            Route::get(
                'purchase-receipts',
                [ PurchaseReceiptController::class, 'index' ]
            );

            Route::post(
                'purchase-receipts/upload',
                [ PurchaseReceiptController::class, 'upload' ]
            );

            Route::put(
                'purchase-receipts/{purchaseReceipt}',
                [ PurchaseReceiptController::class, 'update' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Sales History and Reprint Invoice
            |--------------------------------------------------------------------------
            */

            Route::get(
                'sales-history',
                [ RestaurantOrderController::class, 'salesHistory' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Purchase Receipts
            |--------------------------------------------------------------------------
            */

            Route::post(
                'purchase-receipts/{purchaseReceipt}/run-ocr',
                [ PurchaseReceiptController::class, 'runOcr' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Delete Receipts
            |--------------------------------------------------------------------------
            */

            Route::delete(
                'purchase-receipts/{purchaseReceipt}',
                [ PurchaseReceiptController::class, 'destroy' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Purchase Receipts
            |--------------------------------------------------------------------------
            */
            Route::post(
                'purchase-receipts/{purchaseReceipt}/convert-to-purchase',
                [ PurchaseReceiptController::class, 'convertToPurchase' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Purchases
            |--------------------------------------------------------------------------
            */

            Route::get(
                'purchases',
                [ PurchaseController::class, 'index' ]
            );

            Route::get(
                'purchases/{purchase}',
                [ PurchaseController::class, 'show' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Suppliers
            |--------------------------------------------------------------------------
            */

            Route::get(
                'suppliers',
                [ SupplierController::class, 'index' ]
            );

            Route::post(
                'suppliers',
                [ SupplierController::class, 'store' ]
            );

            Route::get(
                'suppliers/{supplier}',
                [ SupplierController::class, 'show' ]
            );

            Route::put(
                'suppliers/{supplier}',
                [ SupplierController::class, 'update' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Stock Movement
            |--------------------------------------------------------------------------
            */
            Route::get(
                'stock-movements',
                [ StockMovementController::class, 'index' ]
            );

            /*
            |--------------------------------------------------------------------------
            | quick-sales
            |--------------------------------------------------------------------------
            */

            Route::post(
                'quick-sales',
                [ QuickSaleController::class, 'store' ]
            );


            /*
            |--------------------------------------------------------------------------
            | Z report
            |--------------------------------------------------------------------------
            */

            Route::get(
                'z-report/daily',
                [ ZReportController::class, 'daily' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Void Quick Sale
            |--------------------------------------------------------------------------
            | Cancels sale, restores stock and keeps audit trail.
            */

            Route::post(
                'quick-sales/{sale}/void',
                [ QuickSaleVoidController::class, 'void' ]
            );

            /*
            |--------------------------------------------------------------------------
            | Quick Sales History
            |--------------------------------------------------------------------------
            */

            Route::get( 'quick-sales-history', [ QuickSaleHistoryController::class, 'index' ] );

            Route::get( '/user', function ( Request $request ) {
                return $request->user();
            }
        )->middleware( 'auth:sanctum' );
