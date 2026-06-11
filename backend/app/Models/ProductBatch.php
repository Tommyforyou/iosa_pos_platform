<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/*
|--------------------------------------------------------------------------
| Product Batch
|--------------------------------------------------------------------------
| Stores pharmacy batch information.
|
| Example:
| Product: Panadol
| Batch: PAN2501
| Expiry: 31/12/2027
| Qty: 1000
|--------------------------------------------------------------------------
*/

class ProductBatch extends Model
{
    /*
    |--------------------------------------------------------------------------
    | Mass Assignable Fields
    |--------------------------------------------------------------------------
    */

    protected $fillable = [
        'product_id',
        'batch_number',
        'expiry_date',
        'quantity',
        'cost_price',
        'selling_price',
    ];

    /*
    |--------------------------------------------------------------------------
    | Product Relationship
    |--------------------------------------------------------------------------
    */

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
