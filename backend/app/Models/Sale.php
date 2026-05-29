<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model {
    protected $fillable = [
        'business_id',
        'customer_id',
        'user_id',
        'invoice_number',
        'sale_type',
        'subtotal',
        'discount_amount',
        'vat_amount',
        'service_charge',
        'total_amount',
        'payment_status',
        'sale_status',
        'notes',
        /*
        |--------------------------------------------------------------------------
        | MRA e-Invoicing
        |--------------------------------------------------------------------------
        */

        'mra_submitted',
        'mra_irn',
        'mra_qr_code',
        'mra_status',
        'mra_submitted_at',
        'mra_response',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'vat_amount' => 'decimal:2',
        'service_charge' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'mra_submitted' => 'boolean',
        'mra_submitted_at' => 'datetime',
        'mra_response' => 'array',
    ];

    public function business(): BelongsTo {
        return $this->belongsTo( Business::class );
    }

    public function customer(): BelongsTo {
        return $this->belongsTo( Customer::class );
    }

    public function user(): BelongsTo {
        return $this->belongsTo( User::class );
    }

    public function items(): HasMany {
        return $this->hasMany( SaleItem::class );
    }

    public function payments(): HasMany {
        return $this->hasMany( Payment::class );
    }
    /*
    |--------------------------------------------------------------------------
    | Payment Allocations
    |--------------------------------------------------------------------------
    */

    public function paymentAllocations() {
        return $this->hasMany( CustomerPaymentAllocation::class );
    }
}
