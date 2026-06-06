<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RestaurantOrder extends Model
{
    protected $fillable = [

        /*
        |--------------------------------------------------------------------------
        | Core Order Information
        |--------------------------------------------------------------------------
        */
        'business_id',
        'restaurant_table_id',
        'user_id',
        'order_number',
        'order_type',
        'status',
        'notes',
        'discount_percentage',
        'buzzer_number',
        'waiter_id',
        'bill_requested_at',
        'bill_requested_by',
        'order_source',

        /*
        |--------------------------------------------------------------------------
        | Payment Fields
        |--------------------------------------------------------------------------
        */

        'payment_status',
        'payment_method',
        'subtotal',
        'tax_amount',
        'discount_amount',
        'total_amount',
        'paid_at',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(RestaurantTable::class, 'restaurant_table_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function waiter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'waiter_id');
    }

    public function billRequestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'bill_requested_by');
    }

    public function items(): HasMany
    {
        return $this->hasMany(RestaurantOrderItem::class);
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
}
