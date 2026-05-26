<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Services\MraService;

class MraSaleController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | Submit Sale To MRA
    |--------------------------------------------------------------------------
    */

    public function submit(
        Sale $sale,
        MraService $mraService
    ) {
        return response()->json(
            $mraService->submitSale( $sale )
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Retry MRA Submission
    |--------------------------------------------------------------------------
    */

    public function retry(
        Sale $sale,
        MraService $mraService
    ) {
        /*
        |--------------------------------------------------------------------------
        | Reset Previous Failed Status
        |--------------------------------------------------------------------------
        */

        $sale->update( [
            'mra_submitted' => false,
        ] );

        return response()->json(
            $mraService->submitSale( $sale )
        );
    }

}
