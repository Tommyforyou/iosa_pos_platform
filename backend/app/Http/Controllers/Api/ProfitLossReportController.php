<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\Purchase;
use Illuminate\Http\Request;

class ProfitLossReportController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Profit & Loss Summary
    |--------------------------------------------------------------------------
    */

    public function summary(Request $request)
    {
        $validated = $request->validate([
            'from' => ['required', 'date'],
            'to' => ['required', 'date'],
        ]);

        $salesExclVat = Sale::whereBetween('created_at', [
                $validated['from'] . ' 00:00:00',
                $validated['to'] . ' 23:59:59',
            ])
            ->where('sale_status', '!=', 'voided')
            ->sum('subtotal');

        $purchasesExclVat = Purchase::whereBetween('invoice_date', [
                $validated['from'],
                $validated['to'],
            ])
            ->where('status', '!=', 'voided')
            ->sum('subtotal_excl_vat');

        $grossProfit =
            (float) $salesExclVat -
            (float) $purchasesExclVat;

        return response()->json([
            'from' => $validated['from'],
            'to' => $validated['to'],

            'sales_excl_vat' => round((float) $salesExclVat, 2),
            'purchases_excl_vat' => round((float) $purchasesExclVat, 2),
            'gross_profit' => round($grossProfit, 2),

            'vat_note' => 'VAT is excluded from Profit & Loss calculation.',
        ]);
    }
}
