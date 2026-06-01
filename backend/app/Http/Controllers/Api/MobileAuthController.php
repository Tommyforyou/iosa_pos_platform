<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/*
|--------------------------------------------------------------------------
| Mobile Authentication Controller
|--------------------------------------------------------------------------
| Handles mobile login and logout for waiter devices.
*/

class MobileAuthController extends Controller
{
    /**
     * --------------------------------------------------------------------------
     * Waiter Login
     * --------------------------------------------------------------------------
     * Authenticates a user and creates a Sanctum token for the mobile waiter app.
     */
    public function login(Request $request)
    {
        /*
        |--------------------------------------------------------------------------
        | Validate Login Request
        |--------------------------------------------------------------------------
        */

        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Find User
        |--------------------------------------------------------------------------
        */

        $user = User::where('email', $validated['email'])->first();

        /*
        |--------------------------------------------------------------------------
        | Validate Password
        |--------------------------------------------------------------------------
        */

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password.',
            ], 401);
        }

        /*
        |--------------------------------------------------------------------------
        | Create Mobile Access Token
        |--------------------------------------------------------------------------
        */

        $token = $user->createToken('waiter-mobile-token')->plainTextToken;

        /*
        |--------------------------------------------------------------------------
        | Return Login Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    /**
     * --------------------------------------------------------------------------
     * Waiter Logout
     * --------------------------------------------------------------------------
     * Deletes the current Sanctum token from the mobile device session.
     */
    public function logout(Request $request)
    {
        /*
        |--------------------------------------------------------------------------
        | Delete Current Token
        |--------------------------------------------------------------------------
        */

        $request->user()->currentAccessToken()->delete();

        /*
        |--------------------------------------------------------------------------
        | Return Logout Response
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }
}