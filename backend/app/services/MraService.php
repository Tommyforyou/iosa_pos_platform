<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MraService
 {
    /*
    |--------------------------------------------------------------------------
    | Generate MRA Authentication Token
    |--------------------------------------------------------------------------
    | MRA does NOT accept plain username/password in the body.
    |
    | Required flow:
    | 1. Generate random AES key.
    | 2. Send that AES key inside an authentication payload.
    | 3. Encrypt the authentication payload using MRA public certificate.
    | 4. Send encrypted payload to MRA with username + ebsMraId headers.
    | 5. MRA returns token + encrypted key.
    */

    public function generateToken(): array
 {
        /*
        |--------------------------------------------------------------------------
        | Step 1: Generate Random AES Key
        |--------------------------------------------------------------------------
        */

        $aesKey = random_bytes( 32 );

        $aesKeyBase64 = base64_encode( $aesKey );

        /*
        |--------------------------------------------------------------------------
        | Step 2: Build Authentication Payload
        |--------------------------------------------------------------------------
        */

        $authPayload = [
            'username' => config( 'services.mra.username' ),
            'password' => config( 'services.mra.password' ),
            'encryptKey' => $aesKeyBase64,
            'refreshToken' => true,
        ];

        /*
        |--------------------------------------------------------------------------
        | Step 3: Encrypt Authentication Payload
        |--------------------------------------------------------------------------
        */

        $encryptedPayload = $this->encryptWithMraPublicKey(
            json_encode( $authPayload )
        );

        /*
        |--------------------------------------------------------------------------
        | Step 4: Build MRA Request Payload
        |--------------------------------------------------------------------------
        */

        $requestPayload = [
            'requestId' => str_replace(
                '-',
                '',
                ( string ) \Illuminate\Support\Str::uuid()
            ),
            'payload' => $encryptedPayload,
        ];

        /*
        |--------------------------------------------------------------------------
        | Step 5: Send Token Request
        |--------------------------------------------------------------------------
        */

        $response = Http::withoutVerifying()
        ->acceptJson()
        ->asJson()
        ->withHeaders( [
            'username' => config( 'services.mra.username' ),
            'ebsMraId' => config( 'services.mra.ebs_mra_id' ),
            'Content-Type' => 'application/json',
        ] )
        ->post(
            config( 'services.mra.auth_url' ),
            $requestPayload
        );

        /*
        |--------------------------------------------------------------------------
        | Step 6: Decrypt MRA Returned Key
        |--------------------------------------------------------------------------
        */

        $body = $response->json();

        $decryptedMraKey = null;

        if (
            $response->successful() &&
            isset( $body[ 'key' ] )
        ) {
            $decryptedMraKey = $this->decryptMraReturnedKey(
                $body[ 'key' ],
                $aesKeyBase64
            );
        }

        /*
        |--------------------------------------------------------------------------
        | Step 7: Return Debug-Friendly Result
        |--------------------------------------------------------------------------
        */

        return [
            'success' => $response->successful(),
            'status' => $response->status(),
            'request_payload' => $requestPayload,
            'body' => $body,
            'raw' => $response->body(),
            'aes_key_base64_for_debug' => $aesKeyBase64,
            'decrypted_mra_key_for_debug' => $decryptedMraKey,
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Encrypt With MRA Public Key
    |--------------------------------------------------------------------------
    | Equivalent to C#:
    |
    | publicKey.Encrypt(
        |     Encoding.UTF8.GetBytes( json ),
        |     RSAEncryptionPadding.Pkcs1
        | )
        */

        private function encryptWithMraPublicKey( string $plainText ): string
 {
            /*
            |--------------------------------------------------------------------------
            | Certificate Path
            |--------------------------------------------------------------------------
            */

            $certPath = storage_path( 'mra/PublicKey.crt' );

            if ( !file_exists( $certPath ) ) {
                throw new \Exception(
                    'MRA public certificate not found at: ' . $certPath
                );
            }

            /*
            |--------------------------------------------------------------------------
            | Load Certificate
            |--------------------------------------------------------------------------
            */

            $certificateContent = file_get_contents( $certPath );

            $publicKey = openssl_pkey_get_public( $certificateContent );

            if ( !$publicKey ) {
                throw new \Exception(
                    'Unable to read MRA public key from certificate.'
                );
            }

            /*
            |--------------------------------------------------------------------------
            | RSA Encrypt Using PKCS1 Padding
            |--------------------------------------------------------------------------
            */

            $encrypted = null;

            $success = openssl_public_encrypt(
                $plainText,
                $encrypted,
                $publicKey,
                OPENSSL_PKCS1_PADDING
            );

            if ( !$success ) {
                throw new \Exception(
                    'Failed to encrypt MRA authentication payload.'
                );
            }

            /*
            |--------------------------------------------------------------------------
            | Return Base64 Encrypted Payload
            |--------------------------------------------------------------------------
            */

            return base64_encode( $encrypted );
        }

        /*
        |--------------------------------------------------------------------------
        | Decrypt MRA Returned Key
        |--------------------------------------------------------------------------
        | MRA returns an encrypted key.
        | We decrypt it using the original AES key generated before authentication.
        */

        private function decryptMraReturnedKey(
            string $encryptedMraKey,
            string $aesKeyBase64
        ): string {
            $encryptedBytes = base64_decode( $encryptedMraKey );

            $aesKey = base64_decode( $aesKeyBase64 );

            $decrypted = openssl_decrypt(
                $encryptedBytes,
                'AES-256-ECB',
                $aesKey,
                OPENSSL_RAW_DATA
            );

            if ( $decrypted === false ) {
                throw new \Exception( 'Failed to decrypt MRA returned key.' );
            }

            return $decrypted;
        }

        /*
        |--------------------------------------------------------------------------
        | Encrypt Invoice Payload
        |--------------------------------------------------------------------------
        | MRA requires the invoice JSON to be encrypted using the decrypted MRA key.
        */

        private function encryptInvoicePayload(
            string $invoiceJson,
            string $decryptedMraKey
        ): string {
            $encrypted = openssl_encrypt(
                $invoiceJson,
                'AES-256-ECB',
                base64_decode( $decryptedMraKey ),
                OPENSSL_RAW_DATA
            );

            if ( $encrypted === false ) {
                throw new \Exception( 'Failed to encrypt invoice payload.' );
            }

            return base64_encode( $encrypted );
        }
        /*
        |--------------------------------------------------------------------------
        | Submit Test Invoice
        |--------------------------------------------------------------------------
        */

        public function submitTestInvoice(): array
 {
            /*
            |--------------------------------------------------------------------------
            | Step 1: Authenticate With MRA
            |--------------------------------------------------------------------------
            */

            $tokenResult = $this->generateToken();

            if ( !$tokenResult[ 'success' ] ) {
                return [
                    'success' => false,
                    'stage' => 'authentication',
                    'token_result' => $tokenResult,
                ];
            }

            $token = $tokenResult[ 'body' ][ 'token' ];

            $decryptedMraKey =
            $tokenResult[ 'decrypted_mra_key_for_debug' ];

            /*
            |--------------------------------------------------------------------------
            | Step 2: Build Sample Invoice JSON
            |--------------------------------------------------------------------------
            */

            $invoiceJson = json_encode( [
                [
                    'invoiceCounter' => '1',
                    'transactionType' => 'B2C',
                    'personType' => 'VATR',
                    'invoiceTypeDesc' => 'STD',
                    'currency' => 'MUR',
                    'invoiceIdentifier' => 'TEST-' . now()->format( 'YmdHis' ),
                    'invoiceRefIdentifier' => '',
                    'previousNoteHash' => 'prevNote',
                    'totalVatAmount' => '37.50',
                    'totalAmtWoVatCur' => '250.00',
                    'totalAmtWoVatMur' => '250.00',
                    'totalAmtPaid' => '287.50',
                    'invoiceTotal' => '287.50',
                    'discountTotalAmount' => '0',
                    'dateTimeInvoiceIssued' => now()->format( 'Ymd H:i:s' ),

                    'seller' => [
                        'name' => 'IOSA Technologies Ltd',
                        'tradeName' => 'IOSA POS',
                        'tan' => '20536895',
                        'brn' => 'C10092761',
                        'businessAddr' => 'Mare Daustralia',
                        'businessPhoneNo' => '57527913',
                        'ebsCounterNo' => '01',
                        'cashierId' => 'Admin',
                    ],

                    'buyer' => [
                        'name' => '',
                        'tan' => '',
                        'brn' => '',
                        'businessAddr' => '',
                        'buyerType' => '',
                        'nic' => '',
                    ],

                    'itemList' => [
                        [
                            'itemNo' => '1',
                            'taxCode' => 'TC01',
                            'nature' => 'GOODS',
                            'productCodeMra' => '',
                            'productCodeOwn' => '',
                            'itemDesc' => 'Test Item',
                            'quantity' => '1',
                            'unitPrice' => '250.00',
                            'discount' => '0',
                            'discountedValue' => '250.00',
                            'amtWoVatCur' => '250.00',
                            'amtWoVatMur' => '250.00',
                            'vatAmt' => '37.50',
                            'totalPrice' => '287.50',
                        ],
                    ],

                    'salesTransactions' => 'CASH',
                ],
            ] );

            /*
            |--------------------------------------------------------------------------
            | Step 3: Encrypt Invoice JSON
            |--------------------------------------------------------------------------
            */

            $encryptedInvoice = $this->encryptInvoicePayload(
                $invoiceJson,
                $decryptedMraKey
            );

            /*
            |--------------------------------------------------------------------------
            | Step 4: Build Transmission Payload
            |--------------------------------------------------------------------------
            */

            $requestPayload = [
                'requestId' => 'REQ-' . now()->format( 'YmdHis' ),
                'requestDateTime' => now()->format( 'Ymd H:i:s' ),
                'encryptedInvoice' => $encryptedInvoice,
            ];

            /*
            |--------------------------------------------------------------------------
            | Step 5: Submit To MRA
            |--------------------------------------------------------------------------
            */

            $response = Http::withoutVerifying()
            ->acceptJson()
            ->asJson()
            ->withHeaders( [
                'username' => config( 'services.mra.username' ),
                'ebsMraId' => config( 'services.mra.ebs_mra_id' ),
                'areaCode' => config( 'services.mra.area_code' ),
                'token' => $token,
                'Content-Type' => 'application/json',
            ] )
            ->post(
                config( 'services.mra.invoice_url' ),
                $requestPayload
            );

            return [
                'success' => $response->successful(),
                'stage' => 'invoice_transmission',
                'status' => $response->status(),
                'request_payload' => $requestPayload,
                'invoice_json_for_debug' => $invoiceJson,
                'body' => $response->json(),
                'raw' => $response->body(),
            ];
        }

        /*
        |--------------------------------------------------------------------------
        | Submit Sale To MRA
        |--------------------------------------------------------------------------
        | This method will:
        |
        | 1. Convert Sale model into MRA invoice JSON
        | 2. Authenticate with MRA
        | 3. Encrypt invoice
        | 4. Submit invoice
        | 5. Save IRN + QR + response
        */

        public function submitSale(
            \App\Models\Sale $sale
        ): array {

        }

    }