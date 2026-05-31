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

        return response()->json([
            'from' => $validated['from'],
            'to' => $validated['to'],

            'sales_excl_vat' => round($salesExclVat, 2),
            'vat_collected' => round($vatCollected, 2),

            'purchases_excl_vat' => round($purchasesExclVat, 2),
            'vat_paid' => round($vatPaid, 2),

            'net_vat_payable' => round($netVatPayable, 2),
        ]);
    }
}