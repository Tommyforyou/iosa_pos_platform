<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupplierPaymentAllocation extends Model {

    protected $fillable = [
        'supplier_payment_id',
        'purchase_id',
        'amount',
    ];

    public function payment() {
        return $this->belongsTo(
            SupplierPayment::class,
            'supplier_payment_id'
        );
    }

    public function purchase() {
        return $this->belongsTo(
            Purchase::class
        );
    }

}
