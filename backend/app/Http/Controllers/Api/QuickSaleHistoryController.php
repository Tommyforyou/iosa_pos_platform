<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use Illuminate\Http\Request;

class QuickSaleHistoryController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Quick Sale History
    |--------------------------------------------------------------------------
    */

    public function index(Request $request)
    {
        $query = Sale::with([
            'customer',
            'items',
        ]);

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('invoice_number', 'ILIKE', '%' . $request->search . '%')
                    ->orWhereHas('customer', function ($customerQuery) use ($request) {
                        $customerQuery->where('name', 'ILIKE', '%' . $request->search . '%')
                            ->orWhere('phone', 'ILIKE', '%' . $request->search . '%')
                            ->orWhere('brn', 'ILIKE', '%' . $request->search . '%');
                    });
            });
        }

        return $query
            ->latest()
            ->limit(300)
            ->get();
    }
}
