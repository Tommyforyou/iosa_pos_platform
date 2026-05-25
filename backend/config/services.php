<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env( 'POSTMARK_API_KEY' ),
    ],

    'resend' => [
        'key' => env( 'RESEND_API_KEY' ),
    ],

    'ses' => [
        'key' => env( 'AWS_ACCESS_KEY_ID' ),
        'secret' => env( 'AWS_SECRET_ACCESS_KEY' ),
        'region' => env( 'AWS_DEFAULT_REGION', 'us-east-1' ),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env( 'SLACK_BOT_USER_OAUTH_TOKEN' ),
            'channel' => env( 'SLACK_BOT_USER_DEFAULT_CHANNEL' ),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Mauritius Revenue Authority ( MRA )
    |--------------------------------------------------------------------------
    */

    'mra' => [

        'username' => env( 'MRA_USERNAME' ),

        'password' => env( 'MRA_PASSWORD' ),

        'ebs_mra_id' => env( 'MRA_EBS_MRA_ID' ),

        'area_code' => env( 'MRA_AREA_CODE' ),

        'auth_url' => env( 'MRA_AUTH_URL' ),

        'invoice_url' => env( 'MRA_INVOICE_URL' ),

        'environment' => env(
            'MRA_ENVIRONMENT',
            'TEST'
        ),

        'public_cert_path' => env(
            'MRA_PUBLIC_CERT_PATH',
            'storage/mra/PublicKey.crt'
        ),
    ],
];

