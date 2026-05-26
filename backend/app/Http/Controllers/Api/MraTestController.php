<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MraService;

class MraTestController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | Test MRA Token Generation
    |--------------------------------------------------------------------------
    */

    public function token( MraService $mraService ) {
        return response()->json(
            $mraService->generateToken()
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Test MRA Invoice Transmission
    |--------------------------------------------------------------------------
    */

    public function submitTestInvoice( MraService $mraService ) {
        return response()->json(
            $mraService->submitTestInvoice()
        );
    }
}