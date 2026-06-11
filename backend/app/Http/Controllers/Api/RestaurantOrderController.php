<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RestaurantOrder;
use App\Models\RestaurantOrderItem;
use App\Models\RestaurantTable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Product;
use App\Models\StockMovement;
use App\Services\KitchenPrintService;
use Illuminate\Support\Facades\Log;


class RestaurantOrderController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Store Restaurant Order
    |--------------------------------------------------------------------------
    | This method receives an order from Flutter.
    | It supports:
    | - dine-in orders with table
    | - takeaway orders without table
    | - delivery orders without table
    |
    | For dine-in:
    | - if the table already has an active order, new items are added to it
    | - if not, a new order is created
    |
    | For takeaway/delivery:
    | - a new order is created each time
    */
    public function store(Request $request)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Incoming Request
        |--------------------------------------------------------------------------
        */
        $validated = $request->validate([
            'restaurant_table_id' => ['nullable', 'exists:restaurant_tables,id'],
            'order_type' => ['required', 'in:dine_in,takeaway,delivery'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'exists:products,id'],
            'items.*.name' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:1'],
            'items.*.price' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
            'waiter_id' => ['nullable', 'exists:users,id'],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Start Database Transaction
        |--------------------------------------------------------------------------
        | This ensures the order, items, and table status are saved together.
        | If anything fails, everything is rolled back.
        */
        DB::beginTransaction();

        try {
            /*
            |--------------------------------------------------------------------------
            | Find Existing Active Dine-In Order
            |--------------------------------------------------------------------------
            | Only dine-in table orders should reuse an existing active order.
            | Takeaway and delivery must create a new order each time.
            */
            $order = null;

            if (
                $validated['order_type'] === 'dine_in' &&
                !empty($validated['restaurant_table_id'])
            ) {
                $order = RestaurantOrder::where('restaurant_table_id', $validated['restaurant_table_id'])
                    ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
                    ->first();
            }

            /*
            |--------------------------------------------------------------------------
            | Create New Order If No Active Order Exists
            |--------------------------------------------------------------------------
            */
            if (!$order) {
                $order = RestaurantOrder::create([
                    'business_id' => 1,
                    'restaurant_table_id' => $validated['restaurant_table_id'] ?? null,
                    'user_id' => null,
                    'order_number' => 'ORD-' . now()->format('YmdHis') . '-' . random_int(1000, 9999),
                    'order_type' => $validated['order_type'],
                    'status' => 'sent_to_kitchen',
                    'notes' => $validated['notes'] ?? null,
                    'daily_order_number' => $this->generateDailyOrderNumber(),
                    //'waiter_id' => $request->user()?->id,
                ]);
            } else {
                /*
                |--------------------------------------------------------------------------
                | Reuse Existing Active Table Order
                |--------------------------------------------------------------------------
                | This allows the waiter to add extra items later to the same table bill.
                */
                $order->update([
                    'status' => 'sent_to_kitchen',
                    'waiter_id' => $validated['waiter_id'] ?? $order->waiter_id,
                ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Save Order Items
            |--------------------------------------------------------------------------
            | Each product added from Flutter cart becomes one kitchen order item.
            */
            foreach ($validated['items'] as $item) {
                RestaurantOrderItem::create([
                    'restaurant_order_id' => $order->id,
                    'product_id' => $item['id'],
                    'product_name' => $item['name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['price'],
                    'kitchen_status' => 'pending',
                    //'waiter_id' => $request->user()?->id,
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Update Table Status
            |--------------------------------------------------------------------------
            | Only dine-in orders should occupy restaurant tables.
            */
            if (
                $validated['order_type'] === 'dine_in' &&
                !empty($validated['restaurant_table_id'])
            ) {
                RestaurantTable::where('id', $validated['restaurant_table_id'])
                    ->update([
                        'status' => 'occupied',
                    ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Commit Transaction
            |--------------------------------------------------------------------------
            */
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order sent to kitchen successfully',
                'order_id' => $order->id,
            ]);
        } catch (\Exception $e) {
            /*
            |--------------------------------------------------------------------------
            | Rollback Transaction On Error
            |--------------------------------------------------------------------------
            */
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Sales History
    |--------------------------------------------------------------------------
    | Returns paid/completed orders with optional date filtering.
    */

    public function salesHistory(Request $request)
    {
        $query = RestaurantOrder::with([
            'table',
            'customer',
            'items',
        ])
            ->whereIn('payment_status', [
                'paid',
            ]);

        if ($request->filled('from')) {
            $from = \Carbon\Carbon::parse($request->from, 'Indian/Mauritius')
                ->startOfDay()
                ->timezone('UTC');

            $query->where('paid_at', '>=', $from);
        }

        if ($request->filled('to')) {
            $to = \Carbon\Carbon::parse($request->to, 'Indian/Mauritius')
                ->endOfDay()
                ->timezone('UTC');

            $query->where('paid_at', '<=', $to);
        }

        return $query
            ->latest('paid_at')
            ->limit(500)
            ->get();
    }


    /*
    |--------------------------------------------------------------------------
    | Kitchen Orders
    |--------------------------------------------------------------------------
    | Returns all active orders that should appear on the kitchen display.
    */
    public function kitchenOrders()
    {
        return RestaurantOrder::with(['table', 'customer', 'items.product'])
            ->whereHas('items', function ($query) {
                $query->whereIn('kitchen_status', [
                    'pending',
                    'preparing',
                    'ready',
                ]);
            })
            ->with([
                'items' => function ($query) {
                    $query->whereIn('kitchen_status', [
                        'pending',
                        'preparing',
                        'ready',
                    ]);
                },
            ])
            ->latest()
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Active Order By Table
    |--------------------------------------------------------------------------
    | Used when a waiter taps an occupied table.
    | It reloads the active order and existing items for that table.
    */
    public function activeOrderByTable($tableId)
    {
        $order = RestaurantOrder::with([
            'table',
            'items.product',
        ])
            ->where('restaurant_table_id', $tableId)
            ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
            ->latest()
            ->first();

        return response()->json([
            'success' => $order ? true : false,
            'order' => $order,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Update Kitchen Item Status
    |--------------------------------------------------------------------------
    | Updates one kitchen item status.
    | Valid statuses:
    | - pending
    | - preparing
    | - ready
    | - served
    | - cancelled
    */
    public function updateKitchenItemStatus(Request $request, $itemId)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Status
        |--------------------------------------------------------------------------
        */
        $validated = $request->validate([
            'kitchen_status' => [
                'required',
                'in:draft,pending,preparing,ready,served,cancelled',
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Find Order Item
        |--------------------------------------------------------------------------
        */
        $item = RestaurantOrderItem::findOrFail($itemId);

        /*
        |--------------------------------------------------------------------------
        | Update Kitchen Status
        |--------------------------------------------------------------------------
        */
        $item->update([
            'kitchen_status' => $validated['kitchen_status'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kitchen item status updated',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Billable Orders
    |--------------------------------------------------------------------------
    | Returns restaurant orders that are ready for billing.
    |
    | This includes:
    | - dine-in active table orders
    | - takeaway orders
    | - delivery orders
    |
    | Later, we can filter only orders where kitchen items are served/ready.
    */
    public function billableOrders()
    {
        return RestaurantOrder::with(['table', 'items'])
            ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
            ->latest()
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Process Payment
    |--------------------------------------------------------------------------
    | Marks restaurant order as paid.
    |
    | Responsibilities:
    | - save payment information
    | - close restaurant order
    | - free dine-in table
    */
    public function processPayment(Request $request, $orderId)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Payment Request
        |--------------------------------------------------------------------------
        */

        $validated = $request->validate([
            /*
            |--------------------------------------------------------------------------
            | Supported Payment Methods
            |--------------------------------------------------------------------------
            | cash
            | card
            | juice
            | cheque
            | complimentary
            | mixed
            */

            'payment_method' => [
                'required',
                'in:cash,card,juice,cheque,complimentary,mixed',
            ],

            'subtotal' => ['required', 'numeric'],
            'tax_amount' => ['required', 'numeric'],
            'discount_amount' => ['required', 'numeric'],
            'discount_percentage' => ['nullable', 'numeric'],
            'total_amount' => ['required', 'numeric'],
        ]);

        DB::beginTransaction();

        try {

            /*
            |--------------------------------------------------------------------------
            | Find Restaurant Order
            |--------------------------------------------------------------------------
            */

            $order = RestaurantOrder::with('table')
                ->findOrFail($orderId);

            /*
            |--------------------------------------------------------------------------
            | Update Payment Information
            |--------------------------------------------------------------------------
            */

            $order->update([

                'payment_status' => 'paid',
                'payment_method' => $validated['payment_method'],

                'subtotal' => $validated['subtotal'],
                'tax_amount' => $validated['tax_amount'],
                'discount_amount' => $validated['discount_amount'],
                'total_amount' => $validated['total_amount'],

                'paid_at' => now(),

                /*
                |--------------------------------------------------------------------------
                | Close Order
                |--------------------------------------------------------------------------
                */

                'status' => 'completed',
            ]);

            /*
            |--------------------------------------------------------------------------
            | Free Dine-In Table
            |--------------------------------------------------------------------------
            */

            if (
                $order->order_type === 'dine_in' &&
                $order->restaurant_table_id
            ) {
                RestaurantTable::where(
                    'id',
                    $order->restaurant_table_id
                )->update([
                    'status' => 'available',
                ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Deduct Inventory Stock
            |--------------------------------------------------------------------------
            */

            $this->deductStockForOrder($order);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Payment processed successfully',
            ]);
        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Deduct Stock For Restaurant Order
    |--------------------------------------------------------------------------
    */

    private function deductStockForOrder(RestaurantOrder $order): void
    {
        /*
        |--------------------------------------------------------------------------
        | Load Order Items
        |--------------------------------------------------------------------------
        */

        $order->load('items');

        foreach ($order->items as $item) {

            /*
            |--------------------------------------------------------------------------
            | Skip Invalid Product
            |--------------------------------------------------------------------------
            */

            if (!$item->product_id) {
                continue;
            }

            $product = Product::find($item->product_id);

            if (!$product) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Prevent Duplicate Stock Deduction
            |--------------------------------------------------------------------------
            */

            $alreadyDeducted = StockMovement::where(
                'remarks',
                'Restaurant sale - ' . $order->order_number
            )
                ->where('product_id', $product->id)
                ->where('movement_type', 'sale')
                ->exists();

            if ($alreadyDeducted) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Calculate Quantity
            |--------------------------------------------------------------------------
            */

            $quantitySold = (float) $item->quantity;

            $beforeQuantity = (float) ($product->stock_quantity ?? 0);

            $afterQuantity = $beforeQuantity - $quantitySold;

            /*
            |--------------------------------------------------------------------------
            | Update Product Stock
            |--------------------------------------------------------------------------
            */

            $product->update([
                'stock_quantity' => $afterQuantity,
            ]);

            /*
            |--------------------------------------------------------------------------
            | Record Stock Movement
            |--------------------------------------------------------------------------
            */

            StockMovement::create([
                'product_id' => $product->id,
                'user_id' => auth()->id(),
                'movement_type' => 'sale',
                'quantity' => -abs($quantitySold),
                'before_quantity' => $beforeQuantity,
                'after_quantity' => $afterQuantity,
                'remarks' => 'Restaurant sale - ' . $order->order_number,
            ]);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Update Kitchen Status
    |--------------------------------------------------------------------------
    | Updates kitchen workflow state.
    */

    public function updateKitchenStatus(
        Request $request,
        RestaurantOrder $restaurantOrder
    ) {
        $validated = $request->validate([
            'status' => [
                'required',
                'in:sent_to_kitchen,preparing,ready,served',
            ],
        ]);

        $restaurantOrder->update([
            'status' => $validated['status'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kitchen status updated',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Sales Dashboard
    |--------------------------------------------------------------------------
    | Returns operational POS dashboard statistics.
    |
    | Current metrics:
    | - today's sales
    | - completed orders
    | - active orders
    | - occupied tables
    | - payment method counts
    |
    | Future metrics:
    | - top products
    | - hourly sales
    | - staff performance
    | - VAT summary
    */
    public function dashboardStats()
    {
        /*
        |--------------------------------------------------------------------------
        | Today's Completed Orders
        |--------------------------------------------------------------------------
        */

        $completedOrders = RestaurantOrder::where(
            'payment_status',
            'paid'
        )
            ->whereDate('paid_at', today())
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Today's Sales Amount
        |--------------------------------------------------------------------------
        */

        $todaySales = RestaurantOrder::where(
            'payment_status',
            'paid'
        )
            ->whereDate('paid_at', today())
            ->sum('total_amount');

        /*
        |--------------------------------------------------------------------------
        | Active Orders
        |--------------------------------------------------------------------------
        */

        $activeOrders = RestaurantOrder::whereIn(
            'status',
            [
                'open',
                'sent_to_kitchen',
                'preparing',
            ]
        )->count();

        /*
        |--------------------------------------------------------------------------
        | Occupied Tables
        |--------------------------------------------------------------------------
        */

        $occupiedTables = RestaurantTable::where(
            'status',
            'occupied'
        )->count();

        /*
        |--------------------------------------------------------------------------
        | Payment Method Statistics
        |--------------------------------------------------------------------------
        */

        $cashPayments = RestaurantOrder::where(
            'payment_method',
            'cash'
        )
            ->whereDate('paid_at', today())
            ->count();

        $cardPayments = RestaurantOrder::where(
            'payment_method',
            'card'
        )
            ->whereDate('paid_at', today())
            ->count();

        return response()->json([

            'today_sales' => round($todaySales, 2),

            'completed_orders' => $completedOrders,

            'active_orders' => $activeOrders,

            'occupied_tables' => $occupiedTables,

            'cash_payments' => $cashPayments,

            'card_payments' => $cardPayments,
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Daily Sales Report
    |--------------------------------------------------------------------------
    | Returns detailed daily POS sales report.
    |
    | Includes:
    | - totals
    | - payment breakdown
    | - completed orders
    | - full order listing
    */
    public function dailySalesReport()
    {
        /*
        |--------------------------------------------------------------------------
        | Today's Paid Orders
        |--------------------------------------------------------------------------
        */

        $orders = RestaurantOrder::with([
            'table',
            'items',
        ])
            ->where('payment_status', 'paid')
            ->whereDate('paid_at', today())
            ->latest()
            ->get();

        /*
        |--------------------------------------------------------------------------
        | Sales Totals
        |--------------------------------------------------------------------------
        */

        $totalSales = $orders->sum('total_amount');

        $cashSales = $orders
            ->where('payment_method', 'cash')
            ->sum('total_amount');

        $cardSales = $orders
            ->where('payment_method', 'card')
            ->sum('total_amount');

        /*
        |--------------------------------------------------------------------------
        | Order Type Breakdown
        |--------------------------------------------------------------------------
        */

        $dineInOrders = $orders
            ->where('order_type', 'dine_in')
            ->count();

        $takeawayOrders = $orders
            ->where('order_type', 'takeaway')
            ->count();

        $deliveryOrders = $orders
            ->where('order_type', 'delivery')
            ->count();

        return response()->json([

            /*
            |--------------------------------------------------------------------------
            | Summary
            |--------------------------------------------------------------------------
            */

            'summary' => [

                'date' => today()->toDateString(),

                'total_sales' => round($totalSales, 2),

                'completed_orders' => $orders->count(),

                'cash_sales' => round($cashSales, 2),

                'card_sales' => round($cardSales, 2),

                'dine_in_orders' => $dineInOrders,

                'takeaway_orders' => $takeawayOrders,

                'delivery_orders' => $deliveryOrders,
            ],

            /*
            |--------------------------------------------------------------------------
            | Order Listing
            |--------------------------------------------------------------------------
            */

            'orders' => $orders,
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Void Restaurant Order Item
    |--------------------------------------------------------------------------
    | Used by cashier/manager to void a disputed item before payment.
    |
    | This does NOT delete the row from database.
    | It marks the item as voided for audit purposes.
    */
    public function voidOrderItem(Request $request, $itemId)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Void Reason
        |--------------------------------------------------------------------------
        */

        $validated = $request->validate([
            'void_reason' => ['required', 'string', 'max:500'],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Find Order Item
        |--------------------------------------------------------------------------
        */

        $item = RestaurantOrderItem::findOrFail($itemId);

        /*
        |--------------------------------------------------------------------------
        | Mark Item As Voided
        |--------------------------------------------------------------------------
        */

        $item->update([
            'is_voided' => true,
            'void_reason' => $validated['void_reason'],
            'voided_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Item voided successfully',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Save Draft Restaurant Order
    |--------------------------------------------------------------------------
    | Used while waiter/cashier is still selecting items.
    |
    | Purpose:
    | - prevent cart from disappearing when screen is closed
    | - save unsent items as draft
    | - do NOT show draft items in kitchen yet
    |
    | Workflow:
    | draft → pending → preparing → ready → served
    */
    public function saveDraftOrder(Request $request)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Draft Order Request
        |--------------------------------------------------------------------------
        */
        $validated = $request->validate([
            'restaurant_table_id' => ['nullable', 'exists:restaurant_tables,id'],
            'order_type' => ['required', 'in:dine_in,takeaway,delivery'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'exists:products,id'],
            'items.*.name' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:1'],
            'items.*.price' => ['required', 'numeric', 'min:0'],

            /*
            |--------------------------------------------------------------------------
            | Kitchen Item Notes
            |--------------------------------------------------------------------------
            */

            'items.*.notes' => ['nullable', 'string'],

            'notes' => ['nullable', 'string'],
            'customer_id' => ['nullable', 'exists:customers,id'],
            'waiter_id' => ['nullable', 'exists:users,id'],
        ]);
        DB::beginTransaction();

        try {
            /*
            |--------------------------------------------------------------------------
            | Find Or Create Active Order
            |--------------------------------------------------------------------------
            | For dine-in, reuse active table order.
            | For takeaway/delivery, create a draft order if no order id exists yet.
            */
            $order = null;

            if (
                $validated['order_type'] === 'dine_in' &&
                !empty($validated['restaurant_table_id'])
            ) {
                $order = RestaurantOrder::where(
                    'restaurant_table_id',
                    $validated['restaurant_table_id']
                )
                    ->whereIn('status', [
                        'open',
                        'sent_to_kitchen',
                        'preparing',
                    ])
                    ->first();
            }

            if (!$order) {
                $order = RestaurantOrder::create([
                    'business_id' => 1,
                    'restaurant_table_id' => $validated['restaurant_table_id'] ?? null,
                    'user_id' => null,
                    'order_number' => 'ORD-' . now()->format('YmdHis') . '-' . random_int(1000, 9999),
                    'order_type' => $validated['order_type'],
                    'status' => 'open',
                    'notes' => $validated['notes'] ?? null,
                    'customer_id' => $validated['customer_id'] ?? null,
                    'waiter_id' => $request->user()?->id,
                    'notes' => $item['notes'] ?? null,
                    'daily_order_number' => $this->generateDailyOrderNumber(),
                ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Remove Existing Draft Items
            |--------------------------------------------------------------------------
            | This prevents duplicate draft rows when waiter saves repeatedly.
            | Already sent kitchen items are kept untouched.
            */
            RestaurantOrderItem::where('restaurant_order_id', $order->id)
                ->where('kitchen_status', 'draft')
                ->delete();

            /*
            |--------------------------------------------------------------------------
            | Save Current Draft Items
            |--------------------------------------------------------------------------
            */
            foreach ($validated['items'] as $item) {
                RestaurantOrderItem::create([
                    'restaurant_order_id' => $order->id,
                    'product_id' => $item['id'],
                    'product_name' => $item['name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['price'],
                    'kitchen_status' => 'draft',
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            /*
            |--------------------------------------------------------------------------
            | Occupy Table For Dine-In Draft
            |--------------------------------------------------------------------------
            | Even draft dine-in orders should reserve/occupy the table.
            */
            if (
                $validated['order_type'] === 'dine_in' &&
                !empty($validated['restaurant_table_id'])
            ) {
                RestaurantTable::where('id', $validated['restaurant_table_id'])
                    ->update([
                        'status' => 'occupied',
                    ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Draft order saved successfully',
                'order_id' => $order->id,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Send Draft Items To Kitchen
    |--------------------------------------------------------------------------
    | Converts all draft items into pending kitchen items.
    |
    | Workflow:
    | draft → pending → preparing → ready → served
    */

    public function sendDraftItemsToKitchen($orderId)
    {
        $order = RestaurantOrder::findOrFail($orderId);

        RestaurantOrderItem::where('restaurant_order_id', $order->id)
            ->where('kitchen_status', 'draft')
            ->update([
                'kitchen_status' => 'pending',
            ]);

        $order->update([
            'status' => 'sent_to_kitchen',
        ]);

        /*
    |--------------------------------------------------------------------------
    | Auto Print - Safe
    |--------------------------------------------------------------------------
    */

        try {
            app(\App\Services\KitchenPrintService::class)->printOrder(
                $order->fresh([
                    'table',
                    'items.product',
                ])
            );
        } catch (\Throwable $e) {
            Log::error(
                'Kitchen auto print failed: ' . $e->getMessage()
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Items sent to kitchen successfully',
        ]);
    }



    /*
    |--------------------------------------------------------------------------
    | Counter Order With Immediate Payment
    |--------------------------------------------------------------------------
    | Used for fast-food / KFC-style counter workflow.
    |
    | This endpoint does everything in one transaction:
    | - creates takeaway order
    | - saves order items
    | - sends items directly to kitchen as pending
    | - records payment
    | - marks order as paid
    | - returns full order data for receipt preview
    |
    | Workflow:
    | Counter Cart → Pay Immediately → Kitchen Receives Order → Receipt
    */
    public function counterOrderPayment(Request $request)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Counter Order Request
        |--------------------------------------------------------------------------
        */
        $validated = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'exists:products,id'],
            'items.*.name' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:1'],
            'items.*.price' => ['required', 'numeric', 'min:0'],
            'buzzer_number' => ['nullable', 'string', 'max:50'],
            'payment_method' => [
                'required',
                'in:cash,card,juice,cheque,complimentary,mixed',
            ],

            'subtotal' => ['required', 'numeric'],
            'tax_amount' => ['required', 'numeric'],
            'discount_amount' => ['required', 'numeric'],
            'discount_percentage' => ['required', 'numeric'],
            'total_amount' => ['required', 'numeric'],

            'notes' => ['nullable', 'string'],
            'buzzer_number' => ['nullable', 'string', 'max:50',],
        ]);

        DB::beginTransaction();

        try {
            /*
            |--------------------------------------------------------------------------
            | Create Counter / Takeaway Order
            |--------------------------------------------------------------------------
            | Counter POS orders do not use table numbers.
            */
            $order = RestaurantOrder::create([
                'business_id' => 1,
                'restaurant_table_id' => null,
                'user_id' => null,
                'order_number' => 'ORD-' . now()->format('YmdHis') . '-' . random_int(1000, 9999),
                'order_type' => 'takeaway',
                'status' => 'sent_to_kitchen',
                'notes' => $validated['notes'] ?? null,
                'buzzer_number' => $validated['buzzer_number'] ?? null,
                'daily_order_number' => $this->generateDailyOrderNumber(),

                /*
                |--------------------------------------------------------------------------
                | Payment Fields
                |--------------------------------------------------------------------------
                */
                'payment_status' => 'paid',
                'payment_method' => $validated['payment_method'],
                'subtotal' => $validated['subtotal'],
                'tax_amount' => $validated['tax_amount'],
                'discount_amount' => $validated['discount_amount'],
                'discount_percentage' => $validated['discount_percentage'],
                'total_amount' => $validated['total_amount'],
                'paid_at' => now(),
            ]);

            /*
            |--------------------------------------------------------------------------
            | Save Kitchen Items
            |--------------------------------------------------------------------------
            | Counter orders go directly to kitchen as pending.
            */
            foreach ($validated['items'] as $item) {
                RestaurantOrderItem::create([
                    'restaurant_order_id' => $order->id,
                    'product_id' => $item['id'],
                    'product_name' => $item['name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['price'],
                    'kitchen_status' => 'pending',
                    'notes' => $item['notes'] ?? null,
                ]);
            }
            /*
            |--------------------------------------------------------------------------
            | Deduct Inventory Stock
            |--------------------------------------------------------------------------
            */

            $this->deductStockForOrder($order);
            DB::commit();

            /*
            |--------------------------------------------------------------------------
            | Return Full Order For Receipt
            |--------------------------------------------------------------------------
            */
            $order->load(['table', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Counter order paid and sent to kitchen',
                'order' => $order->fresh(['table', 'customer', 'items']),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /*
|--------------------------------------------------------------------------
| Deduct Stock For Paid Order
|--------------------------------------------------------------------------
| Inventory deduction logic:
|
| If product has recipe/BOM:
|     deduct ingredient stock
|
| Else:
|     deduct finished product stock
|
| This supports:
| - restaurants
| - fast food
| - hybrid inventory models
*/
    private function olddeductStockForOrder(RestaurantOrder $order): void
    {
        $order->load('items');

        foreach ($order->items as $item) {

            /*
        |--------------------------------------------------------------------------
        | Skip Voided Items
        |--------------------------------------------------------------------------
        */

            if ($item->is_voided) {
                continue;
            }

            /*
        |--------------------------------------------------------------------------
        | Find Product
        |--------------------------------------------------------------------------
        */

            $product = \App\Models\Product::with('recipes.ingredient')
                ->find($item->product_id);

            if (!$product) {
                continue;
            }

            /*
        |--------------------------------------------------------------------------
        | Recipe / BOM Inventory Deduction
        |--------------------------------------------------------------------------
        */

            if ($product->recipes->count() > 0) {

                foreach ($product->recipes as $recipe) {

                    $ingredient = $recipe->ingredient;

                    if (!$ingredient) {
                        continue;
                    }

                    /*
                |--------------------------------------------------------------------------
                | Calculate Ingredient Consumption
                |--------------------------------------------------------------------------
                */

                    $quantityToDeduct =
                        $recipe->quantity_required * $item->quantity;

                    $beforeQuantity =
                        $ingredient->stock_quantity;

                    $afterQuantity =
                        $beforeQuantity - $quantityToDeduct;

                    /*
                |--------------------------------------------------------------------------
                | Update Ingredient Stock
                |--------------------------------------------------------------------------
                */

                    $ingredient->update([
                        'stock_quantity' => $afterQuantity,
                    ]);

                    /*
                |--------------------------------------------------------------------------
                | Ingredient Stock Movement
                |--------------------------------------------------------------------------
                */

                    \App\Models\StockMovement::create([
                        'product_id' => $product->id,
                        'user_id' => null,
                        'movement_type' => 'ingredient_consumption',
                        'quantity' => $quantityToDeduct,
                        'before_quantity' => $beforeQuantity,
                        'after_quantity' => $afterQuantity,
                        'remarks' =>
                        'Ingredient deduction for product ' .
                            $product->name .
                            ' from order ' .
                            $order->order_number,
                    ]);
                }
            } else {

                /*
            |--------------------------------------------------------------------------
            | Fallback Finished Product Deduction
            |--------------------------------------------------------------------------
            | Used when no BOM/recipe exists.
            */

                $beforeQuantity = $product->stock_quantity;

                $afterQuantity =
                    $beforeQuantity - $item->quantity;

                $product->update([
                    'stock_quantity' => $afterQuantity,
                ]);

                /*
            |--------------------------------------------------------------------------
            | Finished Product Stock Movement
            |--------------------------------------------------------------------------
            */

                \App\Models\StockMovement::create([
                    'product_id' => $product->id,
                    'user_id' => null,
                    'movement_type' => 'sale',
                    'quantity' => $item->quantity,
                    'before_quantity' => $beforeQuantity,
                    'after_quantity' => $afterQuantity,
                    'remarks' =>
                    'Stock deducted from restaurant order ' .
                        $order->order_number,
                ]);
            }
        }
    }

    /**
     * --------------------------------------------------------------------------
     * Request Bill
     * --------------------------------------------------------------------------
     * Called by waiter mobile application when customer requests the bill.
     * Records the request timestamp and the waiter responsible.
     */


    public function requestBill(Request $request, $orderId)
    {
        /*
    |--------------------------------------------------------------------------
    | Find Order
    |--------------------------------------------------------------------------
    */

        $order = RestaurantOrder::findOrFail($orderId);

        /*
    |--------------------------------------------------------------------------
    | Mark Bill Requested
    |--------------------------------------------------------------------------
    */

        $order->update([
            'bill_requested_at' => now(),
            'bill_requested_by' => $request->user()?->id,
        ]);

        /*
    |--------------------------------------------------------------------------
    | Return Response
    |--------------------------------------------------------------------------
    */

        return response()->json([
            'success' => true,
            'message' => 'Bill requested successfully.',
        ]);
    }
    /**
     * --------------------------------------------------------------------------
     * Waiter Active Orders
     * --------------------------------------------------------------------------
     * Returns all active restaurant orders that are still being processed.
     * Used by the waiter mobile application to monitor order progress.
     *
     * Included Relationships:
     * - Table Information
     * - Order Items
     * - Product Details
     * - Assigned Waiter
     */
    public function waiterOrders(Request $request)
    {
        $orders = RestaurantOrder::with([
            'table',
            'items.product',
            'waiter',
        ])
            ->whereNotNull('restaurant_table_id')
            ->whereIn('status', [
                'open',
                'sent_to_kitchen',
                'preparing',
                'ready',
            ])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    /**
     * --------------------------------------------------------------------------
     * Get Pending Bill Requests
     * --------------------------------------------------------------------------
     */
    public function pendingBillRequests()
    {
        $orders = RestaurantOrder::with([
            'table',
            'waiter'
        ])
            ->whereNotNull('bill_requested_at')
            ->where('status', 'open')
            ->latest('bill_requested_at')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }


    /*
|--------------------------------------------------------------------------
| Customer Orders
|--------------------------------------------------------------------------
*/
    public function customerOrders()
    {
        return RestaurantOrder::with([
            'table',
            'items'
        ])
            ->where('status', 'customer_pending')
            ->latest()
            ->get();
    }

    /*
|--------------------------------------------------------------------------
| Approve Customer Order
|--------------------------------------------------------------------------
*/

    public function approveCustomerOrder(
        RestaurantOrder $order
    ) {
        RestaurantOrderItem::where(
            'restaurant_order_id',
            $order->id
        )
            ->update([
                'kitchen_status' => 'pending',
            ]);


        /*
    |--------------------------------------------------------------------------
    | Update Order Status
    |--------------------------------------------------------------------------
    */
        $order->update([
            'status' => 'sent_to_kitchen',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Order approved.',
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Reject Customer Order
|--------------------------------------------------------------------------
*/
    public function rejectCustomerOrder(
        RestaurantOrder $order
    ) {
        $order->update([
            'status' => 'rejected',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Order rejected.',
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Customer Orders Count
|--------------------------------------------------------------------------
*/

    public function customerOrdersCount()
    {
        return response()->json([
            'count' => RestaurantOrder::where(
                'status',
                'customer_pending'
            )->count(),
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Store Kiosk Order
|--------------------------------------------------------------------------
| Kiosk orders are created as payment pending.
| They must be paid at cashier before being sent to kitchen.
*/

    public function storeKioskOrder(Request $request)
    {
        /*
    |--------------------------------------------------------------------------
    | Validate Request
    |--------------------------------------------------------------------------
    */

        $validated = $request->validate([
            'order_type' => ['required', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'integer'],
            'items.*.name' => ['required', 'string'],
            'items.*.price' => ['required', 'numeric'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'notes' => ['nullable', 'string'],
        ]);

        /*
    |--------------------------------------------------------------------------
    | Calculate Total
    |--------------------------------------------------------------------------
    */

        $subtotal = collect($validated['items'])->sum(function ($item) {
            return $item['price'] * $item['quantity'];
        });


        /*
        |--------------------------------------------------------------------------
        | Generate Kiosk Order Number
        |--------------------------------------------------------------------------
        */

        $orderNumber = 'K-' . now()->format('YmdHis') . '-' . rand(100, 999);

        /*
    |--------------------------------------------------------------------------
    | Create Kiosk Order
    |--------------------------------------------------------------------------
    */
        $dailyOrderNumber = $this->generateDailyOrderNumber();
        $order = RestaurantOrder::create([
            'business_id' => 1,
            'restaurant_table_id' => null,
            'order_number' => $orderNumber,
            'order_type' => $validated['order_type'],
            'status' => 'kiosk_payment_pending',
            'order_source' => 'kiosk',
            'subtotal' => $subtotal,
            'total_amount' => $subtotal,
            'notes' => $validated['notes'] ?? 'Kiosk Order',

        ]);

        $order->daily_order_number = $dailyOrderNumber;
        $order->save();


        /*
    |--------------------------------------------------------------------------
    | Create Draft Items
    |--------------------------------------------------------------------------
    | Kitchen status remains draft until cashier receives payment.
    */

        foreach ($validated['items'] as $item) {
            RestaurantOrderItem::create([
                'restaurant_order_id' => $order->id,
                'product_id' => $item['id'],
                'product_name' => $item['name'],
                'quantity' => $item['quantity'],
                'unit_price' => $item['price'],
                'kitchen_status' => 'draft',
                'notes' => null,
            ]);
        }

        /*
        |--------------------------------------------------------------------------
        | Return Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Kiosk order created. Please pay at cashier.',
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'daily_order_number' => $order->daily_order_number,
            'total_amount' => $order->total_amount,
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Kiosk Pending Orders
|--------------------------------------------------------------------------
*/

    public function kioskPendingOrders()
    {
        return RestaurantOrder::with([
            'items',
        ])
            ->where('status', 'kiosk_payment_pending')
            ->where('order_source', 'kiosk')
            ->latest()
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Pay Kiosk Order
    |--------------------------------------------------------------------------
    | Once paid, the order is sent to kitchen.
    */

    public function payKioskOrder(
        Request $request,
        RestaurantOrder $order
    ) {
        /*
        |--------------------------------------------------------------------------
        | Validate Request
        |--------------------------------------------------------------------------
        */

        $validated = $request->validate([
            'payment_method' => [
                'required',
                'string',
                'in:cash,card,juice,bank_transfer',
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Mark Order As Paid And Send To Kitchen
        |--------------------------------------------------------------------------
        */

        $order->update([
            'status' => 'sent_to_kitchen',
            'payment_status' => 'paid',
            'payment_method' => $validated['payment_method'],
            'paid_at' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | Send Draft Items To Kitchen
        |--------------------------------------------------------------------------
        */

        RestaurantOrderItem::where(
            'restaurant_order_id',
            $order->id
        )
            ->where('kitchen_status', 'draft')
            ->update([
                'kitchen_status' => 'pending',
            ]);

        /*
        |--------------------------------------------------------------------------
        | Return Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Kiosk order paid and sent to kitchen.',
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'daily_order_number' => $order->daily_order_number,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Order Status Display
    |--------------------------------------------------------------------------
    */

    public function orderStatusDisplay()
    {
        $received = RestaurantOrder::whereHas('items', function ($query) {
            $query->where('kitchen_status', 'pending');
        })
            ->with('items')
            ->latest()
            ->get();

        $preparing = RestaurantOrder::whereHas('items', function ($query) {
            $query->where('kitchen_status', 'preparing');
        })
            ->with('items')
            ->latest()
            ->get();

        $ready = RestaurantOrder::whereHas('items', function ($query) {
            $query->where('kitchen_status', 'ready');
        })
            ->with('items')
            ->latest()
            ->get();

        return response()->json([
            'received' => $received,
            'preparing' => $preparing,
            'ready' => $ready,
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Generate Daily Order Number
    |--------------------------------------------------------------------------
    */

    private function generateDailyOrderNumber(): int
    {
        $lastNumber = RestaurantOrder::whereDate(
            'created_at',
            today()
        )->max('daily_order_number');

        return ((int) $lastNumber) + 1;
    }
    /*
    |--------------------------------------------------------------------------
    | Kitchen Performance Dashboard
    |--------------------------------------------------------------------------
    | Provides real-time kitchen metrics for management and supervisors.
    |
    | Metrics:
    | - Orders received today
    | - Pending items
    | - Items being prepared
    | - Ready items
    | - Longest waiting order
    | - Delayed orders (> 15 minutes)
    |--------------------------------------------------------------------------
    */

    public function kitchenPerformanceDashboard()
    {
        /*
        |--------------------------------------------------------------------------
        | Today's Date
        |--------------------------------------------------------------------------
        */

        $today = today();

        /*
        |--------------------------------------------------------------------------
        | Orders Received Today
        |--------------------------------------------------------------------------
        */

        $ordersToday = RestaurantOrder::whereDate(
            'created_at',
            $today
        )->count();

        /*
        |--------------------------------------------------------------------------
        | Pending Kitchen Items
        |--------------------------------------------------------------------------
        */

        $pendingItems = RestaurantOrderItem::where(
            'kitchen_status',
            'pending'
        )
            ->whereDate('created_at', $today)
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Currently Preparing Items
        |--------------------------------------------------------------------------
        */

        $currentlyPreparing = RestaurantOrderItem::where(
            'kitchen_status',
            'preparing'
        )
            ->whereDate('created_at', $today)
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Ready Items
        |--------------------------------------------------------------------------
        */

        $readyItems = RestaurantOrderItem::where(
            'kitchen_status',
            'ready'
        )
            ->whereDate('created_at', $today)
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Longest Waiting Active Order
        |--------------------------------------------------------------------------
        */

        $longestWaitingOrder = RestaurantOrder::whereHas(
            'items',
            function ($query) {
                $query->whereIn('kitchen_status', [
                    'pending',
                    'preparing',
                ]);
            }
        )
            ->whereDate('created_at', $today)
            ->oldest()
            ->first();

        /*
        |--------------------------------------------------------------------------
        | Waiting Time In Minutes
        |--------------------------------------------------------------------------
        */

        $longestWaitingMinutes = $longestWaitingOrder
            ? $longestWaitingOrder
            ->created_at
            ->diffInMinutes(now())
            : 0;

        /*
        |--------------------------------------------------------------------------
        | Delayed Orders
        |--------------------------------------------------------------------------
        | Orders waiting more than 15 minutes.
        |--------------------------------------------------------------------------
    */

        $delayedOrders = RestaurantOrder::whereHas(
            'items',
            function ($query) {
                $query->whereIn('kitchen_status', [
                    'pending',
                    'preparing',
                ]);
            }
        )
            ->whereDate('created_at', $today)
            ->where(
                'created_at',
                '<=',
                now()->subMinutes(15)
            )
            ->count();

        /*
        |--------------------------------------------------------------------------
        | API Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'orders_today' => $ordersToday,
            'pending_items' => $pendingItems,
            'currently_preparing' => $currentlyPreparing,
            'ready_items' => $readyItems,
            'longest_waiting_minutes' => $longestWaitingMinutes,
            'delayed_orders' => $delayedOrders,

            'longest_waiting_order' => $longestWaitingOrder
                ? [
                    'id' => $longestWaitingOrder->id,
                    'daily_order_number' =>
                    $longestWaitingOrder->daily_order_number,
                    'order_number' =>
                    $longestWaitingOrder->order_number,
                    'order_type' =>
                    $longestWaitingOrder->order_type,
                    'created_at' =>
                    $longestWaitingOrder->created_at,
                ]
                : null,
        ]);
    }
}
