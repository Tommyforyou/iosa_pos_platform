<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomerPayment extends Model {
    /*
    |--------------------------------------------------------------------------
    | Mass Assignable
    |--------------------------------------------------------------------------
    */

    protected $fillable = [

        'customer_id',
        'amount',
        'payment_method',
        'reference',
        'notes',
        'payment_date',

    ];

    /*
    |--------------------------------------------------------------------------
    | Casts
    |--------------------------------------------------------------------------
    */

    protected $casts = [

        'amount' => 'decimal:2',
        'payment_date' => 'date',

    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function customer() {
        return $this->belongsTo( Customer::class );
    }

    /*
    |--------------------------------------------------------------------------
    | Payment Allocations
    |--------------------------------------------------------------------------
    */

    public function allocations() {
        return $this->hasMany( CustomerPaymentAllocation::class );
    }
}