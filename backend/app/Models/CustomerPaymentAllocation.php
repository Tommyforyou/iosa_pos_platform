<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomerPaymentAllocation extends Model
{
    /*
    |--------------------------------------------------------------------------
    | Mass Assignable
    |--------------------------------------------------------------------------
    */

    protected $fillable = [

        'customer_payment_id',
        'sale_id',
        'amount',

    ];

    /*
    |--------------------------------------------------------------------------
    | Casts
    |--------------------------------------------------------------------------
    */

    protected $casts = [

        'amount' => 'decimal:2',

    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function payment()
    {
        return $this->belongsTo(
            CustomerPayment::class,
            'customer_payment_id'
        );
    }

    public function sale()
    {
        return $this->belongsTo(Sale::class);
    }
}