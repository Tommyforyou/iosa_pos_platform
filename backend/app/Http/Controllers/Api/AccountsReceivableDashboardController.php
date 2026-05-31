<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Sale;
use App\Models\CustomerPayment;

class AccountsReceivableDashboardController extends Controller
{
/*
|--------------------------------------------------------------------------
| Accounts Receivable Dashboard
|--------------------------------------------------------------------------
*/

public function index()
{
    /*
    |--------------------------------------------------------------------------
    | KPI Totals
    |--------------------------------------------------------------------------
    */

    $totalCustomers = Customer::count();

    $totalSales = Sale::where('sale_status', '!=', 'voided')
        ->sum('total_amount');

    $totalReceived = CustomerPayment::sum('amount');

    $outstandingReceivables =
        $totalSales - $totalReceived;

    /*
    |--------------------------------------------------------------------------
    | Aging Buckets
    |--------------------------------------------------------------------------
    */

    $current = 0;
    $days31_60 = 0;
    $days61_90 = 0;
    $days90Plus = 0;

    $sales = Sale::where('sale_status', '!=', 'voided')
        ->where('payment_status', '!=', 'paid')
        ->get();

    foreach ($sales as $sale) {
        $allocatedAmount = (float) $sale
            ->paymentAllocations()
            ->sum('amount');

        $outstanding =
            (float) $sale->total_amount - $allocatedAmount;

        if ($outstanding <= 0) {
            continue;
        }

        $ageDays = $sale->created_at->diffInDays(now());

        if ($ageDays <= 30) {
            $current += $outstanding;
        } elseif ($ageDays <= 60) {
            $days31_60 += $outstanding;
        } elseif ($ageDays <= 90) {
            $days61_90 += $outstanding;
        } else {
            $days90Plus += $outstanding;
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Top Customers Owing
    |--------------------------------------------------------------------------
    */

    $topCustomers = Customer::get()
        ->map(function ($customer) {
            $salesTotal = $customer->sales()
                ->where('sale_status', '!=', 'voided')
                ->sum('total_amount');

            $paymentsTotal = $customer->payments()
                ->sum('amount');

            return [
                'id' => $customer->id,
                'name' => $customer->name,
                'outstanding_balance' => round(
                    $salesTotal - $paymentsTotal,
                    2
                ),
            ];
        })
        ->filter(function ($customer) {
            return $customer['outstanding_balance'] > 0;
        })
        ->sortByDesc('outstanding_balance')
        ->take(10)
        ->values();

    /*
    |--------------------------------------------------------------------------
    | Recent Customer Payments
    |--------------------------------------------------------------------------
    */

    $recentPayments = CustomerPayment::with('customer:id,name')
        ->latest()
        ->take(10)
        ->get();

    return response()->json([
        'total_customers' => $totalCustomers,

        'total_sales' => round($totalSales, 2),

        'total_received' => round($totalReceived, 2),

        'outstanding_receivables' => round($outstandingReceivables, 2),

        'aging' => [
            'current' => round($current, 2),
            'days_31_60' => round($days31_60, 2),
            'days_61_90' => round($days61_90, 2),
            'days_90_plus' => round($days90Plus, 2),
        ],

        'top_customers' => $topCustomers,

        'recent_payments' => $recentPayments,
    ]);
}
}