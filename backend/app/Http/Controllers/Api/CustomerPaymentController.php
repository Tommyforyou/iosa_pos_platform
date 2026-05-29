<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerPayment;
use Illuminate\Http\Request;
use App\Models\Sale;
use App\Models\CustomerPaymentAllocation;
use Illuminate\Support\Facades\DB;


class CustomerPaymentController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Store Customer Payment
    |--------------------------------------------------------------------------
    */

    public function store(Request $request, Customer $customer)
    {
        $validated = $request->validate([
        'amount' => ['required', 'numeric', 'min:0.01'],
        'payment_method' => ['required', 'in:cash,card,juice,cheque,bank_transfer'],
        'reference' => ['nullable', 'string', 'max:255'],
        'notes' => ['nullable', 'string'],
        'payment_date' => ['required', 'date'],
    ]);

    return DB::transaction(function () use ($validated, $customer) {

        /*
        |--------------------------------------------------------------------------
        | Create Customer Payment
        |--------------------------------------------------------------------------
        */

        $payment = CustomerPayment::create([
            'customer_id' => $customer->id,
            'amount' => $validated['amount'],
            'payment_method' => $validated['payment_method'],
            'reference' => $validated['reference'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'payment_date' => $validated['payment_date'],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Auto Allocate Payment To Oldest Unpaid Sales
        |--------------------------------------------------------------------------
        */

        $remainingAmount = (float) $validated['amount'];

        $sales = Sale::where('customer_id', $customer->id)
            ->where('sale_status', '!=', 'voided')
            ->oldest()
            ->get();

        foreach ($sales as $sale) {

            if ($remainingAmount <= 0) {
                break;
            }

            /*
            |--------------------------------------------------------------------------
            | Calculate Already Allocated Amount
            |--------------------------------------------------------------------------
            */

            $allocatedAmount = (float) $sale
                ->paymentAllocations()
                ->sum('amount');

            $outstandingAmount =
                (float) $sale->total_amount - $allocatedAmount;

            if ($outstandingAmount <= 0) {
                continue;
            }

            /*
            |--------------------------------------------------------------------------
            | Allocate Payment
            |--------------------------------------------------------------------------
            */

            $amountToAllocate = min(
                $remainingAmount,
                $outstandingAmount
            );

            CustomerPaymentAllocation::create([
                'customer_payment_id' => $payment->id,
                'sale_id' => $sale->id,
                'amount' => $amountToAllocate,
            ]);

            $remainingAmount -= $amountToAllocate;

            /*
            |--------------------------------------------------------------------------
            | Update Sale Payment Status
            |--------------------------------------------------------------------------
            */

            $newAllocatedAmount =
                $allocatedAmount + $amountToAllocate;

            if ($newAllocatedAmount >= (float) $sale->total_amount) {
                $sale->update([
                    'payment_status' => 'paid',
                ]);
            } else {
                $sale->update([
                    'payment_status' => 'partial',
                ]);
            }
        }

        /*
        |--------------------------------------------------------------------------
        | Return Payment With Allocations
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Customer payment recorded and allocated successfully.',
            'payment' => $payment->fresh([
                'allocations.sale',
            ]),
            'unallocated_amount' => round($remainingAmount, 2),
        ], 201);
    });
}
}