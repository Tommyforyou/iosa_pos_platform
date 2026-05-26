<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BusinessSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BusinessSettingController extends Controller {
    /*
    |--------------------------------------------------------------------------
    | Show Business Settings
    |--------------------------------------------------------------------------
    */

    public function show() {
        $settings = BusinessSetting::firstOrCreate( [] );

        return response()->json( $settings );
    }

    /*
    |--------------------------------------------------------------------------
    | Upload Business Logo
    |--------------------------------------------------------------------------
    */

    public function uploadLogo( Request $request ) {
        $validated = $request->validate( [
            'logo' => [ 'required', 'image', 'max:2048' ],
        ] );

        $settings = BusinessSetting::firstOrCreate( [] );

        if ( $settings->logo_path ) {
            Storage::disk( 'public' )->delete( $settings->logo_path );
        }

        $path = $request->file( 'logo' )->store( 'business-logo', 'public' );

        $settings->update( [
            'logo_path' => $path,
        ] );

        return response()->json( [
            'success' => true,
            'message' => 'Business logo uploaded successfully',
            'settings' => $settings->fresh(),
            'logo_url' => asset( 'storage/' . $path ),
        ] );
    }

    /*
    |--------------------------------------------------------------------------
    | Update Business Settings
    |--------------------------------------------------------------------------
    */

    public function update( Request $request ) {
        $validated = $request->validate( [
            'company_name' => [ 'nullable', 'string', 'max:255' ],
            'brn' => [ 'nullable', 'string', 'max:255' ],
            'vat_number' => [ 'nullable', 'string', 'max:255' ],
            'address' => [ 'nullable', 'string' ],
            'phone' => [ 'nullable', 'string', 'max:255' ],
            'email' => [ 'nullable', 'email', 'max:255' ],
            'receipt_footer' => [ 'nullable', 'string' ],
            'default_print_format' => [ 'nullable', 'in:thermal,a4' ],
            'mra_enabled' => [ 'nullable', 'boolean' ],
        ] );

        $settings = BusinessSetting::firstOrCreate( [] );

        $settings->update( $validated );

        return response()->json( [
            'success' => true,
            'message' => 'Business settings updated successfully',
            'settings' => $settings->fresh(),
        ] );
    }
}