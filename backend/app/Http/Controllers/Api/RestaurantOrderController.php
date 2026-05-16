<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RestaurantOrder;
use App\Models\RestaurantOrderItem;
use App\Models\RestaurantTable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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
                    'order_number' => 'ORD-' . time(),
                    'order_type' => $validated['order_type'],
                    'status' => 'sent_to_kitchen',
                    'notes' => $validated['notes'] ?? null,
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
    | Kitchen Orders
    |--------------------------------------------------------------------------
    | Returns all active orders that should appear on the kitchen display.
    */
    public function kitchenOrders()
    {
        return RestaurantOrder::with(['table', 'items'])
            ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
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
                'in:pending,preparing,ready,served,cancelled',
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
            'payment_method' => [
                'required',
                'in:cash,card,mixed',
            ],

            'subtotal' => ['required', 'numeric'],
            'tax_amount' => ['required', 'numeric'],
            'discount_amount' => ['required', 'numeric'],
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

}