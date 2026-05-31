<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Purchase extends Model {
    /*
    |--------------------------------------------------------------------------
    | Fillable
    |--------------------------------------------------------------------------
    */

    protected $fillable = [
        'business_id',
        'supplier_id',
        'purchase_receipt_id',
        'invoice_number',
        'invoice_date',
        'subtotal_excl_vat',
        'vat_amount',
        'total_incl_vat',
        'status',
        'payment_status',
        'paid_amount',
        'balance_amount',
        'paid_at',

    ];

    /*
    |--------------------------------------------------------------------------
    | Casts
    |--------------------------------------------------------------------------
    */

    protected $casts = [
        'invoice_date' => 'date',
        'paid_amount' => 'decimal:2',
        'balance_amount' => 'decimal:2',
        'paid_at' => 'datetime',
    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function supplier() {
        return $this->belongsTo(
            Supplier::class
        );
    }

    public function receipt() {
        return $this->belongsTo(
            PurchaseReceipt::class,
            'purchase_receipt_id'
        );
    }

    public function items() {
        return $this->hasMany(
            PurchaseItem::class
        );
    }

    public function supplierPaymentAllocations() {
        return $this->hasMany(
            SupplierPaymentAllocation::class
        );
    }
}