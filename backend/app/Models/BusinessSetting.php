<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BusinessSetting extends Model {
    protected $fillable = [
        'company_name',
        'brn',
        'vat_number',
        'address',
        'phone',
        'email',
        'logo_path',
        'receipt_footer',
        'default_print_format',
        'mra_enabled',
    ];

    protected $casts = [
        'mra_enabled' => 'boolean',
    ];
}
