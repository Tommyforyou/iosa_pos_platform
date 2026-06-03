<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Printer;
use Illuminate\Http\Request;
use App\Services\KitchenPrintService;

/*
|--------------------------------------------------------------------------
| Printer Controller
|--------------------------------------------------------------------------
*/

class PrinterController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | List Printers
    |--------------------------------------------------------------------------
    */

    public function index()
    {
        return response()->json(
            Printer::orderBy('location')
                ->orderBy('name')
                ->get()
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Store Printer
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'ip_address' => ['required', 'string', 'max:255'],
            'port' => ['required', 'integer'],
            'location' => ['required', 'in:kitchen,bar,cashier'],
            'auto_print' => ['boolean'],
            'is_active' => ['boolean'],
        ]);

        $printer = Printer::create($validated);

        return response()->json($printer, 201);
    }

    /*
    |--------------------------------------------------------------------------
    | Update Printer
    |--------------------------------------------------------------------------
    */

    public function update(Request $request, Printer $printer)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'ip_address' => ['required', 'string', 'max:255'],
            'port' => ['required', 'integer'],
            'location' => ['required', 'in:kitchen,bar,cashier'],
            'auto_print' => ['boolean'],
            'is_active' => ['boolean'],
        ]);

        $printer->update($validated);

        return response()->json($printer);
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Printer
    |--------------------------------------------------------------------------
    */

    public function destroy(Printer $printer)
    {
        $printer->delete();

        return response()->json([
            'success' => true,
            'message' => 'Printer deleted successfully.',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Test Print
    |--------------------------------------------------------------------------
    */

    public function testPrint(Printer $printer)
    {
        $service = app(KitchenPrintService::class);

        $printed = $service->testPrint($printer);

        return response()->json([
            'success' => $printed,
            'message' => $printed
                ? 'Test print sent successfully.'
                : 'Test print failed. Check printer connection.',
        ], $printed ? 200 : 500);
    }
}