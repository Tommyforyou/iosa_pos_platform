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

    public function index()
    {
        return Customer::orderBy('name')->get();
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
    | Update Customer
    |--------------------------------------------------------------------------
    */

    public function update(Request $request, Customer $customer)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:255'],
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