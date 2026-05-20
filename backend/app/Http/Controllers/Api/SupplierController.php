<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Supplier;
use Illuminate\Http\Request;

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
}