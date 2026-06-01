<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RestaurantOrderItem extends Model {
    protected $fillable = [
        'restaurant_order_id',
        'product_id',
        'product_name',
        'quantity',
        'unit_price',
        'kitchen_status',
        'notes',
        'is_voided',
        'void_reason',
        'voided_at',
        'waiter_id',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
    ];

    public function order(): BelongsTo {
        return $this->belongsTo( RestaurantOrder::class, 'restaurant_order_id' );
    }

    public function product(): BelongsTo {
        return $this->belongsTo( Product::class );
    }

    public function waiter(): BelongsTo {
        return $this->belongsTo( User::class, 'waiter_id' );
    }
}