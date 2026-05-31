<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Supplier;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Purchase;
use App\Models\SupplierPayment;
use App\Models\SupplierPaymentAllocation;


class SupplierController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Supplier List
    |--------------------------------------------------------------------------
    */

    public function index(Request $request)
    {
        $query = Supplier::withCount('purchases');

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'ILIKE', '%' . $request->search . '%')
                    ->orWhere('brn', 'ILIKE', '%' . $request->search . '%')
                    ->orWhere('vat_number', 'ILIKE', '%' . $request->search . '%');
            });
        }

        return $query
            ->orderBy('name')
            ->limit(500)
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Supplier Detail
    |--------------------------------------------------------------------------
    */

    public function show(Supplier $supplier)
    {
        return $supplier->load([
            'purchases.items',
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Create Supplier
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'brn' => ['nullable', 'string', 'max:255'],
            'vat_number' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $supplier = Supplier::create([
            'business_id' => 1,
            'name' => $validated['name'],
            'brn' => $validated['brn'] ?? null,
            'vat_number' => $validated['vat_number'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'email' => $validated['email'] ?? null,
            'address' => $validated['address'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Supplier created successfully',
            'supplier' => $supplier,
        ], 201);
    }
    /*
    |--------------------------------------------------------------------------
    | Update Supplier
    |--------------------------------------------------------------------------
    */

    public function update(Request $request, Supplier $supplier)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'brn' => ['nullable', 'string', 'max:255'],
            'vat_number' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $supplier->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Supplier updated successfully',
            'supplier' => $supplier->fresh(),
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Supplier Balance
    |--------------------------------------------------------------------------
    */

    public function balance(Supplier $supplier)
    {
        /*
        |--------------------------------------------------------------------------
        | Total Purchases
        |--------------------------------------------------------------------------
        */

        $totalPurchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('total_incl_vat');

        /*
        |--------------------------------------------------------------------------
        | Total Paid
        |--------------------------------------------------------------------------
        */

        $totalPaid = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('paid_amount');

        /*
        |--------------------------------------------------------------------------
        | Outstanding Balance
        |--------------------------------------------------------------------------
        */

        $outstanding = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('balance_amount');

        return response()->json([
            'supplier_id' => $supplier->id,
            'supplier_name' => $supplier->name,
            'total_purchases' => round($totalPurchases, 2),
            'total_paid' => round($totalPaid, 2),
            'outstanding_balance' => round($outstanding, 2),
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Supplier Transactions
|--------------------------------------------------------------------------
*/

public function transactions(Supplier $supplier)
{
    /*
    |--------------------------------------------------------------------------
    | Purchase Transactions
    |--------------------------------------------------------------------------
    */

    $purchases = $supplier->purchases()
        ->where('status', '!=', 'voided')
        ->get()
        ->map(function ($purchase) {
            return [
                'type' => 'purchase',
                'date' => $purchase->invoice_date ?? $purchase->created_at,
                'reference' => $purchase->invoice_number,
                'amount' => $purchase->total_incl_vat,
                'status' => $purchase->payment_status ?? 'paid',
            ];
        });

    /*
    |--------------------------------------------------------------------------
    | Supplier Payment Transactions
    |--------------------------------------------------------------------------
    */

    $payments = $supplier->payments()
        ->get()
        ->map(function ($payment) {
            return [
                'type' => 'payment',
                'date' => $payment->payment_datetime ?? $payment->payment_date,
                'reference' => $payment->reference ?? ('SPAY-' . $payment->id),
                'amount' => $payment->amount,
                'status' => $payment->payment_method,
            ];
        });

        /*
        |--------------------------------------------------------------------------
        | Merge Transactions
        |--------------------------------------------------------------------------
        */

        $transactions = $purchases
            ->concat($payments)
            ->sortBy('date')
            ->values();

        /*
        |--------------------------------------------------------------------------
        | Running Balance
        |--------------------------------------------------------------------------
        */

        $balance = 0;

        $transactions = $transactions->map(function ($tx) use (&$balance) {
            if ($tx['type'] === 'purchase') {
                $balance += (float) $tx['amount'];
            }

            if ($tx['type'] === 'payment') {
                $balance -= (float) $tx['amount'];
            }

            $tx['balance'] = round($balance, 2);

            return $tx;
        });

        return response()->json([
            'supplier_id' => $supplier->id,
            'supplier_name' => $supplier->name,
            'transactions' => $transactions->sortByDesc('date')->values(),
        ]);
}

    /*
    |--------------------------------------------------------------------------
    | Supplier Outstanding Purchases
    |--------------------------------------------------------------------------
    */

    public function outstandingPurchases(Supplier $supplier)
    {
        $purchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->where('balance_amount', '>', 0)
            ->oldest()
            ->get()
            ->map(function ($purchase) {
                return [
                    'id' => $purchase->id,
                    'invoice_number' => $purchase->invoice_number,
                    'date' => $purchase->invoice_date ?? $purchase->created_at,
                    'total_amount' => round((float) $purchase->total_incl_vat, 2),
                    'paid_amount' => round((float) $purchase->paid_amount, 2),
                    'outstanding_amount' => round((float) $purchase->balance_amount, 2),
                    'payment_status' => $purchase->payment_status ?? 'paid',
                ];
            });

        return response()->json([
            'supplier_id' => $supplier->id,
            'supplier_name' => $supplier->name,
            'purchases' => $purchases,
        ]);
    }


    /*
    |--------------------------------------------------------------------------
    | Supplier Aging Analysis
    |--------------------------------------------------------------------------
    */

    public function aging(Supplier $supplier)
    {
        $buckets = [
            'current' => 0,
            'days_31_60' => 0,
            'days_61_90' => 0,
            'days_90_plus' => 0,
        ];

        $purchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->where('balance_amount', '>', 0)
            ->get();

        foreach ($purchases as $purchase) {
            $outstanding = (float) $purchase->balance_amount;

            $date = $purchase->invoice_date ?? $purchase->created_at;

            $ageDays = \Carbon\Carbon::parse($date)->diffInDays(now());

            if ($ageDays <= 30) {
                $buckets['current'] += $outstanding;
            } elseif ($ageDays <= 60) {
                $buckets['days_31_60'] += $outstanding;
            } elseif ($ageDays <= 90) {
                $buckets['days_61_90'] += $outstanding;
            } else {
                $buckets['days_90_plus'] += $outstanding;
            }
        }

        return response()->json([
            'supplier_id' => $supplier->id,
            'supplier_name' => $supplier->name,
            'aging' => [
                'current' => round($buckets['current'], 2),
                'days_31_60' => round($buckets['days_31_60'], 2),
                'days_61_90' => round($buckets['days_61_90'], 2),
                'days_90_plus' => round($buckets['days_90_plus'], 2),
            ],
        ]);
    }


    /*
    |--------------------------------------------------------------------------
    | Supplier Statement
    |--------------------------------------------------------------------------
    */

    public function statement(Supplier $supplier)
    {
        $openingBalance = 0;

        $totalPurchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('total_incl_vat');

        $totalPayments = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('paid_amount');

        $closingBalance = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('balance_amount');

        $outstandingPurchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->where('balance_amount', '>', 0)
            ->oldest()
            ->get()
            ->map(function ($purchase) {
                return [
                    'id' => $purchase->id,
                    'invoice_number' => $purchase->invoice_number,
                    'date' => $purchase->invoice_date ?? $purchase->created_at,
                    'total_amount' => round((float) $purchase->total_incl_vat, 2),
                    'paid_amount' => round((float) $purchase->paid_amount, 2),
                    'outstanding_amount' => round((float) $purchase->balance_amount, 2),
                    'payment_status' => $purchase->payment_status ?? 'paid',
                ];
            });


        /*
        |--------------------------------------------------------------------------
        | Purchase Transactions
        |--------------------------------------------------------------------------
        */

        $purchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->get()
            ->map(function ($purchase) {
                return [
                    'date' => $purchase->invoice_date ?? $purchase->created_at,
                    'type' => 'purchase',
                    'reference' => $purchase->invoice_number,
                    'debit' => (float) $purchase->total_incl_vat,
                    'credit' => 0,
                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Supplier Payment Transactions
        |--------------------------------------------------------------------------
        */

        $payments = $supplier->payments()
            ->get()
            ->map(function ($payment) {
                return [
                    'date' => $payment->payment_datetime
                        ?? $payment->payment_date
                        ?? $payment->created_at,
                    'type' => 'payment',
                    'reference' => $payment->reference ?? ('SPAY-' . $payment->id),
                    'debit' => 0,
                    'credit' => (float) $payment->amount,
                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Merge Transactions
        |--------------------------------------------------------------------------
        */

        $transactions = $purchases
            ->concat($payments)
            ->sortBy('date')
            ->values();

        /*
        |--------------------------------------------------------------------------
        | Running Balance
        |--------------------------------------------------------------------------
        */

        $runningBalance = 0;
        $transactions = $transactions->map(function ($tx) use (&$runningBalance) {

            $runningBalance +=
                ((float) $tx['debit']) -
                ((float) $tx['credit']);

            $tx['balance'] = round($runningBalance, 2);

            return $tx;
        });
        
        /*
        |--------------------------------------------------------------------------
        | Statement Totals
        |--------------------------------------------------------------------------
        */

        $totalPurchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->sum('total_incl_vat');

        $totalPayments = $supplier->payments()
            ->sum('amount');

        $closingBalance =
            $totalPurchases - $totalPayments;

            return response()->json([
            'supplier' => $supplier,
            'opening_balance' => $openingBalance,
            'total_purchases' => round($totalPurchases,2),
            'total_payments' => round($totalPayments,2),
            'closing_balance' => round($closingBalance,2),
            'outstanding_purchases' => $outstandingPurchases,
            'transactions' => $transactions,
        ]);
    }

    /*
|--------------------------------------------------------------------------
| Record Supplier Payment
|--------------------------------------------------------------------------
| Creates a supplier payment and automatically allocates it to the oldest
| outstanding purchases first.
*/

public function recordPayment(
    Request $request,
    Supplier $supplier
) {
    $validated = $request->validate([
        'amount' => ['required', 'numeric', 'min:0.01'],
        'payment_method' => ['required', 'string'],
        'payment_date' => ['required', 'date'],
        'reference' => ['nullable', 'string'],
        'notes' => ['nullable', 'string'],

    ]);

    return DB::transaction(function () use (
        $validated,
        $supplier
    ) {
        /*
        |--------------------------------------------------------------------------
        | Create Supplier Payment
        |--------------------------------------------------------------------------
        */

        $payment = SupplierPayment::create([
            'business_id' => 1,
            'supplier_id' => $supplier->id,
            'payment_date' => $validated['payment_date'],
            'payment_datetime' => now(),
            'amount' => $validated['amount'],
            'payment_method' => $validated['payment_method'],
            'reference' => $validated['reference'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        /*
        |--------------------------------------------------------------------------
        | Auto Allocate To Oldest Outstanding Purchases
        |--------------------------------------------------------------------------
        */

        $remainingAmount = (float) $validated['amount'];

        $purchases = $supplier->purchases()
            ->where('status', '!=', 'voided')
            ->where('balance_amount', '>', 0)
            ->oldest('invoice_date')
            ->get();

        foreach ($purchases as $purchase) {
            if ($remainingAmount <= 0) {
                break;
            }

            $balanceAmount =
                (float) $purchase->balance_amount;

            $amountToAllocate =
                min($remainingAmount, $balanceAmount);

            /*
            |--------------------------------------------------------------------------
            | Create Allocation Record
            |--------------------------------------------------------------------------
            */

            SupplierPaymentAllocation::create([
                'supplier_payment_id' => $payment->id,
                'purchase_id' => $purchase->id,
                'amount' => $amountToAllocate,
            ]);

            /*
            |--------------------------------------------------------------------------
            | Update Purchase Payment Totals
            |--------------------------------------------------------------------------
            */

            $newPaidAmount =
                (float) $purchase->paid_amount + $amountToAllocate;

            $newBalanceAmount =
                (float) $purchase->total_incl_vat - $newPaidAmount;

            $purchase->update([
                'paid_amount' => $newPaidAmount,
                'balance_amount' => max($newBalanceAmount, 0),
                'payment_status' =>
                    $newBalanceAmount <= 0
                        ? 'paid'
                        : 'partial',
                'paid_at' =>
                    $newBalanceAmount <= 0
                        ? now()
                        : null,
            ]);

            $remainingAmount -= $amountToAllocate;
        }

        /*
        |--------------------------------------------------------------------------
        | Return Result
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Supplier payment recorded successfully.',
            'payment' => $payment->fresh([
                'supplier',
                'allocations.purchase',
            ]),
            'unallocated_amount' => round($remainingAmount, 2),
        ], 201);
    });
}

















}