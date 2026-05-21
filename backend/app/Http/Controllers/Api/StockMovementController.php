<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class StockMovementController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Stock Movement List
    |--------------------------------------------------------------------------
    */

    public function index(Request $request)
    {
        $query = StockMovement::with([
            'product',
            'user',
        ]);

        if ($request->filled('product')) {
            $query->whereHas('product', function ($productQuery) use ($request) {
                $productQuery->where(
                    'name',
                    'ILIKE',
                    '%' . $request->product . '%'
                );
            });
        }

        if ($request->filled('movement_type')) {
            $query->where(
                'movement_type',
                $request->movement_type
            );
        }

        if ($request->filled('from')) {
            $query->whereDate(
                'created_at',
                '>=',
                $request->from
            );
        }

        if ($request->filled('to')) {
            $query->whereDate(
                'created_at',
                '<=',
                $request->to
            );
        }

        return $query
            ->latest()
            ->limit(500)
            ->get();
    }
}