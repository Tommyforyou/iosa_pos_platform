<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Customer List
    |--------------------------------------------------------------------------
    */

    public function index(Request $request)
    {
        $query = Customer::query();

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'ILIKE', '%' . $request->search . '%')
                    ->orWhere('phone', 'ILIKE', '%' . $request->search . '%')
                    ->orWhere('brn', 'ILIKE', '%' . $request->search . '%')
                    ->orWhere('vat_number', 'ILIKE', '%' . $request->search . '%');
            });
        }

        return $query
            ->orderBy('name')
            ->limit(100)
            ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Search Customer By Phone
    |--------------------------------------------------------------------------
    */

    public function searchByPhone(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
        ]);

        $customer = Customer::where(
            'phone',
            $request->phone
        )->first();

        return response()->json([
            'success' => true,
            'customer' => $customer,
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Store Customer
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:255'],
            'brn' => ['nullable', 'string', 'max:255'],
            'vat_number' => ['nullable', 'string', 'max:255'],      
            'address' => ['nullable', 'string'],
            'email' => ['nullable', 'email'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $customer = Customer::updateOrCreate(
            [
                'phone' => $validated['phone'],
            ],
            [
                'business_id' => 1,
                'name' => $validated['name'],
                'address' => $validated['address'] ?? null,
                'brn' => $validated['brn'] ?? null,
                'vat_number' => $validated['vat_number'] ?? null,
                'email' => $validated['email'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'is_active' => $validated['is_active'] ?? true,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Customer saved successfully',
            'customer' => $customer,
        ]);
    }


    /*
    |--------------------------------------------------------------------------
    | Customer Outstanding Balance
    |--------------------------------------------------------------------------
    */

    public function balance(Customer $customer)
    {
        /*
        |--------------------------------------------------------------------------
        | Total Credit Sales
        |--------------------------------------------------------------------------
        */

        $totalSales = $customer->sales()
            ->where('sale_status', '!=', 'voided')
            ->sum('total_amount');

        /*
        |--------------------------------------------------------------------------
        | Total Payments
        |--------------------------------------------------------------------------
        */

        $totalPayments = $customer->payments()
            ->sum('amount');

        /*
        |--------------------------------------------------------------------------
        | Outstanding Balance
        |--------------------------------------------------------------------------
        */

        $outstanding =
            $totalSales - $totalPayments;

        return response()->json([

            'customer_id' => $customer->id,

            'customer_name' => $customer->name,

            'total_sales' => round($totalSales, 2),

            'total_payments' => round($totalPayments, 2),

            'outstanding_balance' => round($outstanding, 2),

        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Customer Aging Analysis
    |--------------------------------------------------------------------------
    */

    public function aging(Customer $customer)
    {
        $buckets = [
            'current' => 0,
            'days_31_60' => 0,
            'days_61_90' => 0,
            'days_90_plus' => 0,
        ];

        $sales = $customer->sales()
            ->where('sale_status', '!=', 'voided')
            ->get();

        foreach ($sales as $sale) {
            $paidAmount = (float) $sale
                ->paymentAllocations()
                ->sum('amount');

            $outstanding =
                (float) $sale->total_amount - $paidAmount;

            if ($outstanding <= 0) {
                continue;
            }

            $ageDays = $sale->created_at->diffInDays(now());

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
            'customer_id' => $customer->id,
            'customer_name' => $customer->name,
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
    | Customer Statement
    |--------------------------------------------------------------------------
    */

    public function statement(Customer $customer)
    {
        /*
        |--------------------------------------------------------------------------
        | Sales / Invoice Transactions
        |--------------------------------------------------------------------------
        */

        $sales = $customer->sales()
            ->where('sale_status', '!=', 'voided')
            ->get()
            ->map(function ($sale) {
                return [
                    'date' => $sale->created_at,
                    'type' => 'invoice',
                    'reference' => $sale->invoice_number,
                    'debit' => (float) $sale->total_amount,
                    'credit' => 0,
                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Payment Transactions
        |--------------------------------------------------------------------------
        */

        $payments = $customer->payments()
            ->get()
            ->map(function ($payment) {
                return [
                    'date' => $payment->payment_date,
                    'type' => 'payment',
                    'reference' => $payment->reference ?? ('PAY-' . $payment->id),
                    'debit' => 0,
                    'credit' => (float) $payment->amount,
                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Merge Transactions
        |--------------------------------------------------------------------------
        */

        $transactions = $sales
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
            $balance += ((float) $tx['debit']) - ((float) $tx['credit']);

            $tx['balance'] = round($balance, 2);

            return $tx;
        });

        /*
        |--------------------------------------------------------------------------
        | Outstanding Invoices
        |--------------------------------------------------------------------------
        */

        $outstandingInvoices = $customer->sales()
            ->where('sale_status', '!=', 'voided')
            ->get()
            ->map(function ($sale) {
                $paidAmount = (float) $sale
                    ->paymentAllocations()
                    ->sum('amount');

                $outstandingAmount =
                    (float) $sale->total_amount - $paidAmount;

                return [
                    'invoice_number' => $sale->invoice_number,
                    'date' => $sale->created_at,
                    'total_amount' => round((float) $sale->total_amount, 2),
                    'paid_amount' => round($paidAmount, 2),
                    'outstanding_amount' => round($outstandingAmount, 2),
                ];
            })
            ->filter(function ($invoice) {
                return $invoice['outstanding_amount'] > 0;
            })
            ->values();

        /*
        |--------------------------------------------------------------------------
        | Statement Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'customer' => $customer,

            'opening_balance' => 0,

            'total_sales' => round($sales->sum('debit'), 2),

            'total_payments' => round($payments->sum('credit'), 2),

            'closing_balance' => round($balance, 2),

            'outstanding_invoices' => $outstandingInvoices,

            'transactions' => $transactions,
        ]);
    }
    /*
    |--------------------------------------------------------------------------
    | Customer Transactions
    |--------------------------------------------------------------------------
    */

    public function transactions(Customer $customer)
    {
        /*
        |--------------------------------------------------------------------------
        | Customer Sales
        |--------------------------------------------------------------------------
        */

        $sales = $customer->sales()
            ->where('sale_status', '!=', 'voided')
            ->latest()
            ->get()
            ->map(function ($sale) {

                return [

                    'type' => 'sale',

                    'date' => $sale->created_at,

                    'reference' => $sale->invoice_number,

                    'amount' => $sale->total_amount,

                'status' => $sale->payment_status ?? 'unpaid',
                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Customer Payments
        |--------------------------------------------------------------------------
        */

        $payments = $customer->payments()
            ->latest()
            ->get()
            ->map(function ($payment) {

                return [

                    'type' => 'payment',

                    'date' => $payment->payment_date,

                    'reference' => $payment->reference,

                    'amount' => $payment->amount,

                    'status' => $payment->payment_method,

                ];
            });

        /*
        |--------------------------------------------------------------------------
        | Merge Transactions
        |--------------------------------------------------------------------------
        */

        $transactions = $sales
            ->concat($payments)
            ->sortByDesc('date')
            ->values();

        return response()->json([

            'customer_id' => $customer->id,

            'customer_name' => $customer->name,

            'transactions' => $transactions,

        ]);
    }

        /*
        |--------------------------------------------------------------------------
        | Customer Outstanding Invoices
        |--------------------------------------------------------------------------
        */

        public function outstandingInvoices(Customer $customer)
        {
            $invoices = $customer->sales()
                ->where('sale_status', '!=', 'voided')
                ->oldest()
                ->get()
                ->map(function ($sale) {

                    $paidAmount = (float) $sale
                        ->paymentAllocations()
                        ->sum('amount');

                    $totalAmount = (float) $sale->total_amount;

                    $outstandingAmount =
                        $totalAmount - $paidAmount;

                    return [
                        'id' => $sale->id,
                        'invoice_number' => $sale->invoice_number,
                        'date' => $sale->created_at,
                        'total_amount' => round($totalAmount, 2),
                        'paid_amount' => round($paidAmount, 2),
                        'outstanding_amount' => round($outstandingAmount, 2),
                        'payment_status' => $sale->payment_status,
                    ];
                })
                ->filter(function ($invoice) {
                    return $invoice['outstanding_amount'] > 0;
                })
                ->values();

            return response()->json([
                'customer_id' => $customer->id,
                'customer_name' => $customer->name,
                'invoices' => $invoices,
            ]);
        }

        /*
        |--------------------------------------------------------------------------
        | Update Customer
        |--------------------------------------------------------------------------
        */

        public function update(Request $request, Customer $customer)
        {
            $validated = $request->validate([
                'name' => ['required', 'string', 'max:255'],
                'phone' => ['required', 'string', 'max:255'],
                'brn' => ['nullable', 'string', 'max:255'],
                'vat_number' => ['nullable', 'string', 'max:255'],            
                'address' => ['nullable', 'string'],
                'email' => ['nullable', 'email'],
                'notes' => ['nullable', 'string'],
                'is_active' => ['nullable', 'boolean'],
            ]);

            $customer->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Customer updated successfully',
                'customer' => $customer,
            ]);
        }
}