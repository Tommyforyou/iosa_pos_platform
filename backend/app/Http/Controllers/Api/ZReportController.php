<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RestaurantOrder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class ZReportController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | Daily Z-Report Summary
    |--------------------------------------------------------------------------
    */

    public function daily( Request $request ) {
        $date = $request->input(
            'date',
            now()->toDateString()
        );

        $orders = RestaurantOrder::query()
        ->whereDate( 'created_at', $date )
        ->where( 'payment_status', 'paid' )
        ->get();

        $totalSales = $orders->sum( 'total_amount' );

        $vatCollected = $orders->sum( 'tax_amount' );

        $discounts = $orders->sum( 'discount_amount' );

        $cashSales = $orders
        ->where( 'payment_method', 'cash' )
        ->sum( 'total_amount' );

        $cardSales = $orders
        ->where( 'payment_method', 'card' )
        ->sum( 'total_amount' );

        $juiceSales = $orders
        ->where( 'payment_method', 'juice' )
        ->sum( 'total_amount' );

        $chequeSales = $orders
        ->where( 'payment_method', 'cheque' )
        ->sum( 'total_amount' );

        $complimentarySales = $orders
        ->where( 'payment_method', 'complimentary' )
        ->sum( 'total_amount' );

        return response()->json( [
            'date' => $date,
            'order_count' => $orders->count(),
            'total_sales' => $totalSales,
            'vat_collected' => $vatCollected,
            'discounts' => $discounts,
            'payment_breakdown' => [
                'cash' => $cashSales,
                'card' => $cardSales,
                'juice' => $juiceSales,
                'cheque' => $chequeSales,
                'complimentary' => $complimentarySales,
            ],
            'cash_expected' => $cashSales,
        ] );
    }
}