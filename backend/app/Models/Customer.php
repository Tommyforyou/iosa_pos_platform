<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends Model {
    protected $fillable = [
        'business_id',
        'name',
        'phone',
        'email',
        'address',
        'credit_limit',
        'current_balance',
        'is_active',
        'brn',
        'vat_number',
    ];

    protected $casts = [
        'credit_limit' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function business(): BelongsTo {
        return $this->belongsTo( Business::class );
    }

    public function sales(): HasMany {
        return $this->hasMany( Sale::class );
    }

    public function payments() {
        return $this->hasMany( CustomerPayment::class );
    }
}