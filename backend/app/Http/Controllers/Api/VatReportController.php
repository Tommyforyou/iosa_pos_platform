<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\Purchase;
use Illuminate\Http\Request;

class VatReportController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | VAT Summary
    |--------------------------------------------------------------------------
    */

    public function summary(Request $request)
    {
        $validated = $request->validate([
            'from' => ['required', 'date'],
            'to' => ['required', 'date'],
        ]);

        $sales = Sale::whereBetween('created_at', [
                $validated['from'] . ' 00:00:00',
                $validated['to'] . ' 23:59:59',
            ])
            ->where('sale_status', '!=', 'voided');

        $purchases = Purchase::whereBetween('invoice_date', [
                $validated['from'],
                $validated['to'],
            ])
            ->where('status', '!=', 'voided');

        $salesExclVat = (float) $sales->sum('subtotal');
        $vatCollected = (float) $sales->sum('vat_amount');

        $purchasesExclVat = (float) $purchases->sum('subtotal_excl_vat');
        $vatPaid = (float) $purchases->sum('vat_amount');

        $netVatPayable = $vatCollected - $vatPaid;

        $salesTransactions = (clone $sales)
            ->with('customer:id,name')
            ->latest()
            ->get()
            ->map(function ($sale) {
                return [
                    'date' => $sale->created_at,
                    'invoice_number' => $sale->invoice_number,
                    'customer' => $sale->customer?->name ?? 'Walk-in',
                    'subtotal' => round((float) $sale->subtotal, 2),
                    'vat_amount' => round((float) $sale->vat_amount, 2),
                    'total_amount' => round((float) $sale->total_amount, 2),
                ];
            });

        $purchaseTransactions = (clone $purchases)
            ->with('supplier:id,name')
            ->latest()
            ->get()
            ->map(function ($purchase) {
                return [
                    'date' => $purchase->invoice_date,
                    'invoice_number' => $purchase->invoice_number,
                    'supplier' => $purchase->supplier?->name ?? '-',
                    'subtotal' => round((float) $purchase->subtotal_excl_vat, 2),
                    'vat_amount' => round((float) $purchase->vat_amount, 2),
                    'total_amount' => round((float) $purchase->total_incl_vat, 2),
                ];
            });




        return response()->json([
            'from' => $validated['from'],
            'to' => $validated['to'],
            'sales_excl_vat' => round($salesExclVat, 2),
            'vat_collected' => round($vatCollected, 2),
            'purchases_excl_vat' => round($purchasesExclVat, 2),
            'vat_paid' => round($vatPaid, 2),
            'net_vat_payable' => round($netVatPayable, 2),
            'sales_transactions' => $salesTransactions,
            'purchase_transactions' => $purchaseTransactions,
        ]);
    }
}