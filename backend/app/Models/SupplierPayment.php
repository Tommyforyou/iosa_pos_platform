<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupplierPayment extends Model {
    /*
    |--------------------------------------------------------------------------
    | Fillable
    |--------------------------------------------------------------------------
    */

    protected $fillable = [
        'business_id',
        'supplier_id',
        'payment_date',
        'amount',
        'payment_method',
        'reference',
        'notes',
        'payment_datetime',
    ];

    protected $casts = [

        'payment_datetime' => 'datetime',

    ];

    public function supplier() {
        return $this->belongsTo( Supplier::class );
    }

    public function allocations() {
        return $this->hasMany(
            SupplierPaymentAllocation::class
        );
    }
}
