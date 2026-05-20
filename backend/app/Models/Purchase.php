<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Purchase extends Model
{
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
    ];

    /*
    |--------------------------------------------------------------------------
    | Casts
    |--------------------------------------------------------------------------
    */

    protected $casts = [
        'invoice_date' => 'date',
    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function supplier()
    {
        return $this->belongsTo(
            Supplier::class
        );
    }

    public function receipt()
    {
        return $this->belongsTo(
            PurchaseReceipt::class,
            'purchase_receipt_id'
        );
    }

    public function items()
    {
        return $this->hasMany(
            PurchaseItem::class
        );
    }
}