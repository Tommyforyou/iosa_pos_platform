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
                    'order_number' => 'ORD-' . now()->format('YmdHis') . '-' . random_int(1000, 9999),
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

            $alreadyDeducted = StockMovement::where('reference_type', 'restaurant_order')
                ->where('reference_id', $order->id)
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
            'notes' => ['nullable', 'string'],
            'customer_id' => ['nullable', 'exists:customers,id'],
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
        /*
        |--------------------------------------------------------------------------
        | Find Active Order
        |--------------------------------------------------------------------------
        */

        $order = RestaurantOrder::findOrFail($orderId);

        /*
        |--------------------------------------------------------------------------
        | Convert Draft Items To Pending
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
        | Update Order Status
        |--------------------------------------------------------------------------
        */

        $order->update([
            'status' => 'sent_to_kitchen',
        ]);

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
            'buzzer_number' => ['nullable','string','max:50', ],
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
}