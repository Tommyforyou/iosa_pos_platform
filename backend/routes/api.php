<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SupplierController;
use App\Http\Controllers\Api\ZReportController;
use App\Http\Controllers\Api\StockMovementController;
use App\Http\Controllers\Api\QuickSaleController;
use App\Http\Controllers\Api\QuickSaleHistoryController;
use App\Http\Controllers\Api\QuickSaleVoidController;
use App\Http\Controllers\Api\BusinessSettingController;
use App\Http\Controllers\Api\MraTestController;
use App\Http\Controllers\Api\MraSaleController;
use App\Http\Controllers\Api\CustomerPaymentController;
use App\Http\Controllers\Api\VatReportController;
use App\Http\Controllers\Api\AccountsReceivableDashboardController;
use App\Http\Controllers\Api\ProfitLossReportController;
use App\Http\Controllers\Api\MobileAuthController;
use App\Http\Controllers\Api\PrinterController;


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
use App\Http\Controllers\Api\AccountsPayableDashboardController;

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
    | GET /api/categories/ {
        id}
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
        | GET /api/products/ {
            id}
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
            | 'Send to Kitchen'
            */

Route::post(
    'restaurant-orders',
    [RestaurantOrderController::class, 'store']
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

Route::patch(
    'restaurant-orders/{orderId}/request-bill',
    [RestaurantOrderController::class, 'requestBill']
);

/*
            |--------------------------------------------------------------------------
            | Waiter Orders
            |--------------------------------------------------------------------------
            */

Route::get(
    'waiter-orders',
    [RestaurantOrderController::class, 'waiterOrders']
);
/*
            |--------------------------------------------------------------------------
            | Waiter Request Bill
            |--------------------------------------------------------------------------
            */

Route::patch(
    'restaurant-orders/{orderId}/request-bill',
    [RestaurantOrderController::class, 'requestBill']
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
Route::apiResource('categories', ProductCategoryController::class);

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

/*
            |--------------------------------------------------------------------------
            | Kitchen Display System
            |--------------------------------------------------------------------------
            */

Route::get(
    'kitchen/orders',
    [RestaurantOrderController::class, 'kitchenOrders']
);

Route::post(
    'kitchen/orders/{restaurantOrder}/status',
    [RestaurantOrderController::class, 'updateKitchenStatus']
);

/*
            |--------------------------------------------------------------------------
            | Customers
            |--------------------------------------------------------------------------
            */

Route::get(
    'customers/search-by-phone',
    [CustomerController::class, 'searchByPhone']
);

Route::apiResource(
    'customers',
    CustomerController::class
)->only([
    'index',
    'store',
    'update',
]);

/*
            |--------------------------------------------------------------------------
            | Purchase Receipt OCR
            |--------------------------------------------------------------------------
            */

Route::get(
    'purchase-receipts',
    [PurchaseReceiptController::class, 'index']
);

Route::post(
    'purchase-receipts/upload',
    [PurchaseReceiptController::class, 'upload']
);

Route::put(
    'purchase-receipts/{purchaseReceipt}',
    [PurchaseReceiptController::class, 'update']
);

/*
            |--------------------------------------------------------------------------
            | Sales History and Reprint Invoice
            |--------------------------------------------------------------------------
            */

Route::get(
    'sales-history',
    [RestaurantOrderController::class, 'salesHistory']
);

/*
            |--------------------------------------------------------------------------
            | Purchase Receipts
            |--------------------------------------------------------------------------
            */

Route::post(
    'purchase-receipts/{purchaseReceipt}/run-ocr',
    [PurchaseReceiptController::class, 'runOcr']
);

/*
            |--------------------------------------------------------------------------
            | Delete Receipts
            |--------------------------------------------------------------------------
            */

Route::delete(
    'purchase-receipts/{purchaseReceipt}',
    [PurchaseReceiptController::class, 'destroy']
);

/*
            |--------------------------------------------------------------------------
            | Purchase Receipts
            |--------------------------------------------------------------------------
            */
Route::post(
    'purchase-receipts/{purchaseReceipt}/convert-to-purchase',
    [PurchaseReceiptController::class, 'convertToPurchase']
);

/*
            |--------------------------------------------------------------------------
            | Purchases
            |--------------------------------------------------------------------------
            */

Route::get(
    'purchases',
    [PurchaseController::class, 'index']
);

Route::get(
    'purchases/{purchase}',
    [PurchaseController::class, 'show']
);

/*
            |--------------------------------------------------------------------------
            | Suppliers
            |--------------------------------------------------------------------------
            */

Route::get(
    'suppliers',
    [SupplierController::class, 'index']
);

Route::post(
    'suppliers',
    [SupplierController::class, 'store']
);

Route::get(
    'suppliers/{supplier}',
    [SupplierController::class, 'show']
);

Route::put(
    'suppliers/{supplier}',
    [SupplierController::class, 'update']
);

/*
            |--------------------------------------------------------------------------
            | Stock Movement
            |--------------------------------------------------------------------------
            */
Route::get(
    'stock-movements',
    [StockMovementController::class, 'index']
);

/*
            |--------------------------------------------------------------------------
            | quick-sales
            |--------------------------------------------------------------------------
            */

Route::post(
    'quick-sales',
    [QuickSaleController::class, 'store']
);

/*
            |--------------------------------------------------------------------------
            | Z report
            |--------------------------------------------------------------------------
            */

Route::get(
    'z-report/daily',
    [ZReportController::class, 'daily']
);

/*
            |--------------------------------------------------------------------------
            | Void Quick Sale
            |--------------------------------------------------------------------------
            | Cancels sale, restores stock and keeps audit trail.
            */

Route::post(
    'quick-sales/{sale}/void',
    [QuickSaleVoidController::class, 'void']
);

/*
            |--------------------------------------------------------------------------
            | Business Settings
            |--------------------------------------------------------------------------
            */

Route::get(
    'business-settings',
    [BusinessSettingController::class, 'show']
);

Route::post(
    'business-settings',
    [BusinessSettingController::class, 'update']
);
/*
            |--------------------------------------------------------------------------
            | Business Logo Upload
            |--------------------------------------------------------------------------
            */

Route::post(
    'business-settings/logo',
    [BusinessSettingController::class, 'uploadLogo']
);
/*
            |--------------------------------------------------------------------------
            | Quick Sales History
            |--------------------------------------------------------------------------
            */

Route::get('quick-sales-history', [QuickSaleHistoryController::class, 'index']);

/*
            |--------------------------------------------------------------------------
            | MRA Test Routes
            |--------------------------------------------------------------------------
            */

Route::get(
    'mra/test-token',
    [MraTestController::class, 'token']
);

/*
            |--------------------------------------------------------------------------
            | MRA Test Invoice Transmission
            |--------------------------------------------------------------------------
            */

Route::get(
    'mra/test-invoice',
    [MraTestController::class, 'submitTestInvoice']
);

/*
            |--------------------------------------------------------------------------
            | Submit Real Sale To MRA
            |--------------------------------------------------------------------------
            */

Route::post(
    'sales/{sale}/submit-mra',
    [MraSaleController::class, 'submit']
);

/*
            |--------------------------------------------------------------------------
            | Retry Failed MRA Submission
            |--------------------------------------------------------------------------
            */

Route::post(
    'sales/{sale}/retry-mra',
    [MraSaleController::class, 'retry']
);

/*
            |--------------------------------------------------------------------------
            | Customer Payments
            |--------------------------------------------------------------------------
            */

Route::post(
    'customers/{customer}/payments',
    [CustomerPaymentController::class, 'store']
);

Route::get(
    'customers/{customer}/balance',
    [CustomerController::class, 'balance']
);

Route::get(
    'customers/{customer}/transactions',
    [CustomerController::class, 'transactions']
);

/*
            |--------------------------------------------------------------------------
            | Customer OS Balance
            |--------------------------------------------------------------------------
            */

Route::get(
    'customers/{customer}/outstanding-invoices',
    [CustomerController::class, 'outstandingInvoices']
);

Route::get(
    'customers/{customer}/statement',
    [CustomerController::class, 'statement']
);
Route::get(
    'customers/{customer}/aging',
    [CustomerController::class, 'aging']
);

/*
            |--------------------------------------------------------------------------
            | Supplier OS Balance
            |--------------------------------------------------------------------------
            */

Route::get(
    'suppliers/{supplier}/balance',
    [SupplierController::class, 'balance']
);

Route::get(
    'suppliers/{supplier}/transactions',
    [SupplierController::class, 'transactions']
);

Route::get(
    'suppliers/{supplier}/outstanding-purchases',
    [SupplierController::class, 'outstandingPurchases']
);

Route::get(
    'suppliers/{supplier}/aging',
    [SupplierController::class, 'aging']
);

Route::get(
    'suppliers/{supplier}/statement',
    [SupplierController::class, 'statement']
);

Route::post(
    'suppliers/{supplier}/payments',
    [SupplierController::class, 'recordPayment']
);

/*
            |--------------------------------------------------------------------------
            | Accounts Payable Dashboard
            |--------------------------------------------------------------------------
            */

Route::get(
    'accounts-payable/dashboard',
    [AccountsPayableDashboardController::class, 'index']
);

/*
            |--------------------------------------------------------------------------
            | VAT Report
            |--------------------------------------------------------------------------
            */

Route::get(
    'reports/vat-summary',
    [VatReportController::class, 'summary']
);

/*
            |--------------------------------------------------------------------------
            | Accounts Receivable Dashboard
            |--------------------------------------------------------------------------
            */
Route::get(
    'accounts-receivable/dashboard',
    [AccountsReceivableDashboardController::class, 'index']
);

Route::get(
    'reports/profit-loss',
    [ProfitLossReportController::class, 'summary']
);

/*
            |--------------------------------------------------------------------------
            | Mobile Waiter Authentication
            |--------------------------------------------------------------------------
            */

Route::post(
    'mobile/login',
    [MobileAuthController::class, 'login']
);

Route::middleware('auth:sanctum')->group(
    function () {
        Route::post(
            'mobile/logout',
            [MobileAuthController::class, 'logout']
        );
    }
);

/*
        |--------------------------------------------------------------------------
        | Mobile Auth Test
        |--------------------------------------------------------------------------
        */

Route::middleware('auth:sanctum')->get(
    '/mobile/me',

    function (Illuminate\Http\Request $request) {

        return response()->json([
            'id' => $request->user()->id,
            'name' => $request->user()->name,
            'email' => $request->user()->email,
        ]);
    }
);


Route::middleware('auth:sanctum')->group(function () {

    Route::get(
        'waiter-orders',
        [RestaurantOrderController::class, 'waiterOrders']
    );
});

Route::middleware('auth:sanctum')->group(function () {

    Route::post(
        '/restaurant-orders/{order}/request-bill',
        [RestaurantOrderController::class, 'requestBill']
    );
});

/*
    |--------------------------------------------------------------------------
    | CRUD Printers
    |--------------------------------------------------------------------------
    */

Route::get('/printers', [PrinterController::class, 'index']);
Route::post('/printers', [PrinterController::class, 'store']);
Route::put('/printers/{printer}', [PrinterController::class, 'update']);
Route::delete('/printers/{printer}', [PrinterController::class, 'destroy']);

Route::post(
    '/printers/{printer}/test-print',
    [PrinterController::class, 'testPrint']
);
/*
    |--------------------------------------------------------------------------
    | Health Check
    |--------------------------------------------------------------------------
    */

Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'app' => 'IOSA POS',
        'version' => '1.0',
        'server_time' => now(),
    ]);
});
/*
|--------------------------------------------------------------------------
| QR Customer Orders
|--------------------------------------------------------------------------
*/

Route::get(
    '/customer-orders',
    [RestaurantOrderController::class, 'customerOrders']
);

Route::post(
    '/customer-orders/{order}/approve',
    [RestaurantOrderController::class, 'approveCustomerOrder']
);

Route::post(
    '/customer-orders/{order}/reject',
    [RestaurantOrderController::class, 'rejectCustomerOrder']
);


/*
|--------------------------------------------------------------------------
| Customer Orders Count
|--------------------------------------------------------------------------
*/

Route::get(
    '/customer-orders-count',
    [RestaurantOrderController::class, 'customerOrdersCount']
);

/*

/*
|--------------------------------------------------------------------------
| Kiosk Orders
|--------------------------------------------------------------------------
*/

Route::post(
    '/kiosk-orders',
    [RestaurantOrderController::class, 'storeKioskOrder']
);

/*
|--------------------------------------------------------------------------
| Kiosk Pending Payments
|--------------------------------------------------------------------------
*/

Route::get(
    '/kiosk-pending-orders',
    [RestaurantOrderController::class, 'kioskPendingOrders']
);

Route::post(
    '/kiosk-orders/{order}/pay',
    [RestaurantOrderController::class, 'payKioskOrder']
);


/*
|--------------------------------------------------------------------------
| Purchase Receipt Lines
|--------------------------------------------------------------------------
*/

Route::post(
    '/purchase-receipts/{purchaseReceipt}/lines',
    [PurchaseReceiptController::class, 'storeLine']
);

Route::put(
    '/purchase-receipt-lines/{line}',
    [PurchaseReceiptController::class, 'updateLine']
);

Route::delete(
    '/purchase-receipt-lines/{line}',
    [PurchaseReceiptController::class, 'deleteLine']
);


Route::get(
    '/order-status-display',
    [RestaurantOrderController::class, 'orderStatusDisplay']
);



/*
|--------------------------------------------------------------------------
| Authenticated User
|--------------------------------------------------------------------------
*/
Route::get(
    '/user',
    function (Request $request) {
        return $request->user();
    }
)->middleware('auth:sanctum');
