<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CustomerMenuController;

Route::get('/', function () {
    return view('welcome');
});


/*
|--------------------------------------------------------------------------
| Customer QR Menu
|--------------------------------------------------------------------------
*/

Route::get(
    '/customer-menu/table/{table}',
    [CustomerMenuController::class, 'show']
);

Route::post(
    '/customer-menu/table/{table}/order',
    [CustomerMenuController::class, 'store']
);
