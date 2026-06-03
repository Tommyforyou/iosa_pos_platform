<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/*
|--------------------------------------------------------------------------
| Printer Model
|--------------------------------------------------------------------------
*/

class Printer extends Model
{
    protected $fillable = [
        'name',
        'ip_address',
        'port',
        'location',
        'auto_print',
        'is_active',
    ];

    protected $casts = [
        'auto_print' => 'boolean',
        'is_active' => 'boolean',
        'port' => 'integer',
    ];
}