<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\ProductCategory;
use App\Models\RestaurantTable;
use Illuminate\Http\Request;

class CustomerMenuController extends Controller
{
    public function show(RestaurantTable $table)
    {
        $categories = ProductCategory::orderBy('name')->get();

        $products = Product::where('is_active', true)
            ->orderBy('name')
            ->get();

        return view(
            'customer-menu.index',
            compact(
                'table',
                'categories',
                'products'
            )
        );
    }

    public function store(Request $request, RestaurantTable $table)
    {
        $validated = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'exists:products,id'],
            'items.*.name' => ['required', 'string'],
            'items.*.quantity' => ['required', 'numeric', 'min:1'],
            'items.*.price' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $order = \App\Models\RestaurantOrder::create([
            'business_id' => 1,
            'restaurant_table_id' => $table->id,
            'order_number' => 'QR-' . now()->format('YmdHis') . '-' . rand(1000, 9999),
            'order_type' => 'dine_in',
            'status' => 'customer_pending',
            'notes' => $validated['notes'] ?? null,
            'subtotal' => collect($validated['items'])->sum(function ($item) {
                return $item['quantity'] * $item['price'];
            }),
            'total_amount' => collect($validated['items'])->sum(function ($item) {
                return $item['quantity'] * $item['price'];
            }),
        ]);

        foreach ($validated['items'] as $item) {
            \App\Models\RestaurantOrderItem::create([
                'restaurant_order_id' => $order->id,
                'product_id' => $item['id'],
                'product_name' => $item['name'],
                'quantity' => $item['quantity'],
                'unit_price' => $item['price'],
                'kitchen_status' => 'draft',
                'notes' => null,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Order submitted successfully. Please wait for waiter confirmation.',
            'order_id' => $order->id,
        ]);
    }
}
