<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseReceipt extends Model {
    /*
    |--------------------------------------------------------------------------
    | Fillable Fields
    |--------------------------------------------------------------------------
    */

    protected $fillable = [
        'business_id',
        'supplier_name',
        'supplier_brn',
        'supplier_vat_number',
        'invoice_number',
        'invoice_date',
        'subtotal_excl_vat',
        'vat_amount',
        'total_incl_vat',
        'document_path',
        'ocr_raw_text',
        'ocr_extracted_data',
        'status',
        'ocr_confidence',
    ];

    protected $appends = [
        'document_url',
    ];

    public function getDocumentUrlAttribute() {
        if ( !$this->document_path ) {
            return null;
        }

        return asset( 'storage/' . $this->document_path );
    }

    /*
    |--------------------------------------------------------------------------
    | Casts
    |--------------------------------------------------------------------------
    */

    protected $casts = [
        'invoice_date' => 'date',
        'ocr_extracted_data' => 'array',
    ];

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function lines() {
        return $this->hasMany(
            PurchaseReceiptLine::class
        );
    }
}
