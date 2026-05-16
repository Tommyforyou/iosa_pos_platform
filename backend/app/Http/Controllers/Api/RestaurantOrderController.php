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
    public function store(Request $request)
    {
        $validated = $request->validate([
            'restaurant_table_id' => ['required', 'exists:restaurant_tables,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'exists:products,id'],
            'items.*.name' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:1'],
            'items.*.price' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        DB::beginTransaction();

        try {
            $order = RestaurantOrder::where('restaurant_table_id', $validated['restaurant_table_id'])
                ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
                ->first();

            if (!$order) {
                $order = RestaurantOrder::create([
                    'business_id' => 1,
                    'restaurant_table_id' => $validated['restaurant_table_id'],
                    'user_id' => null,
                    'order_number' => 'ORD-' . time(),
                    'order_type' => 'dine_in',
                    'status' => 'sent_to_kitchen',
                    'notes' => $validated['notes'] ?? null,
                ]);
            } else {
                $order->update([
                    'status' => 'sent_to_kitchen',
                ]);
            }

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

            RestaurantTable::where('id', $validated['restaurant_table_id'])
                ->update([
                    'status' => 'occupied',
                ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order sent to kitchen successfully',
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
    
    public function kitchenOrders()
    {
        return RestaurantOrder::with(['table', 'items'])
            ->whereIn('status', ['open', 'sent_to_kitchen', 'preparing'])
            ->latest()
            ->get();
    }

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

}