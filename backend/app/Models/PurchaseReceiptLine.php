<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseReceiptLine extends Model
{
    /*
    |--------------------------------------------------------------------------
    | Fillable Fields
    |--------------------------------------------------------------------------
    */

    protected $fillable = [
        'purchase_receipt_id',
        'description',
        'quantity',
        'unit_price',
        'line_total',
    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function purchaseReceipt()
    {
        return $this->belongsTo(
            PurchaseReceipt::class
        );
    }
}