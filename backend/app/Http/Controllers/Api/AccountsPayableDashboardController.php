<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Supplier;
use App\Models\Purchase;
use App\Models\SupplierPayment;

class AccountsPayableDashboardController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | Accounts Payable Dashboard
    |--------------------------------------------------------------------------
    */

    public function index() {

        /*
        |--------------------------------------------------------------------------
        | KPI Totals
        |--------------------------------------------------------------------------
        */

        $totalSuppliers = Supplier::count();

        $totalPurchases = Purchase::where(
            'status',
            '!=',
            'voided'
        )->sum( 'total_incl_vat' );

        $totalPaid = SupplierPayment::sum(
            'amount'
        );

        $outstandingPayables = Purchase::where(
            'status',
            '!=',
            'voided'
        )->sum( 'balance_amount' );

        /*
        |--------------------------------------------------------------------------
        | Aging Buckets
        |--------------------------------------------------------------------------
        */

        $current = 0;
        $days31_60 = 0;
        $days61_90 = 0;
        $days90Plus = 0;

        $purchases = Purchase::where(
            'status',
            '!=',
            'voided'
        )
        ->where( 'balance_amount', '>', 0 )
        ->get();

        foreach ( $purchases as $purchase ) {

            $ageDays =
            \Carbon\Carbon::parse(
                $purchase->invoice_date
            )->diffInDays( now() );

            $balance =
            ( float ) $purchase->balance_amount;

            if ( $ageDays <= 30 ) {
                $current += $balance;
            } elseif ( $ageDays <= 60 ) {
                $days31_60 += $balance;
            } elseif ( $ageDays <= 90 ) {
                $days61_90 += $balance;
            } else {
                $days90Plus += $balance;
            }
        }

        /*
        |--------------------------------------------------------------------------
        | Top Suppliers Owed
        |--------------------------------------------------------------------------
        */

        $topSuppliers = Supplier::withSum(
            ['purchases as outstanding_balance' => function ($query) {
                $query->where(
                    'balance_amount',
                    '>',
                    0
                );
            }],
            'balance_amount'
        )
        ->orderByDesc('outstanding_balance')
        ->take(10)
        ->get([
            'id',
            'name',
        ]);

        /*
        |--------------------------------------------------------------------------
        | Recent Payments
        |--------------------------------------------------------------------------
        */

        $recentPayments = SupplierPayment::with(
            'supplier:id,name'
        )
        ->latest()
        ->take(10)
        ->get();

        return response()->json([

            'total_suppliers' =>
                $totalSuppliers,

            'total_purchases' =>
                round($totalPurchases, 2),

            'total_paid' =>
                round($totalPaid, 2),

            'outstanding_payables' =>
                round($outstandingPayables, 2),

            'aging' => [
                'current' =>
                    round($current, 2),

                'days_31_60' =>
                    round($days31_60, 2),

                'days_61_90' =>
                    round($days61_90, 2),

                'days_90_plus' =>
                    round($days90Plus, 2),
            ],

            'top_suppliers' =>
                $topSuppliers,

            'recent_payments' =>
                $recentPayments,
        ]);

    }
}