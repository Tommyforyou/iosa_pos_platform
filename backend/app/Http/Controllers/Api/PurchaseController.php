<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Purchase;

class PurchaseController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Purchase List
    |--------------------------------------------------------------------------
    */

public function index(\Illuminate\Http\Request $request)
{
    $query = Purchase::with([
            'supplier',
            'items',
            'receipt',
        ]);

    if ($request->filled('from')) {
        $query->whereDate(
            'invoice_date',
            '>=',
            $request->from
        );
    }

    if ($request->filled('to')) {
        $query->whereDate(
            'invoice_date',
            '<=',
            $request->to
        );
    }

    if ($request->filled('supplier')) {
        $query->whereHas('supplier', function ($supplierQuery) use ($request) {
            $supplierQuery->where(
                'name',
                'ILIKE',
                '%' . $request->supplier . '%'
            );
        });
    }

    return $query
        ->latest('invoice_date')
        ->limit(500)
        ->get();
}

    /*
    |--------------------------------------------------------------------------
    | Purchase Detail
    |--------------------------------------------------------------------------
    */

    public function show(Purchase $purchase)
    {
        return $purchase->load([
            'supplier',
            'items',
            'receipt',
        ]);
    }
}
