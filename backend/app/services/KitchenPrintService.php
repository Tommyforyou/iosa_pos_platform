<?php

namespace App\Services;

use App\Models\Printer as PrinterModel;
use Mike42\Escpos\Printer;
use Mike42\Escpos\PrintConnectors\NetworkPrintConnector;

class KitchenPrintService
 {
    /**
    * Print kitchen order
    */

    public function printOrder( $order ): bool
 {
        try {

            /*
            |--------------------------------------------------------------------------
            | Get Kitchen Printer
            |--------------------------------------------------------------------------
            */

            $printerConfig = PrinterModel::where( 'location', 'kitchen' )
            ->where( 'auto_print', true )
            ->first();

            if ( !$printerConfig ) {
                return false;
            }

            /*
            |--------------------------------------------------------------------------
            | Connect Printer
            |--------------------------------------------------------------------------
            */

            $connector = new NetworkPrintConnector(
                $printerConfig->ip_address,
                $printerConfig->port ?? 9100
            );

            $printer = new Printer( $connector );

            /*
            |--------------------------------------------------------------------------
            | Header
            |--------------------------------------------------------------------------
            */

            $printer->setJustification( Printer::JUSTIFY_CENTER );

            $printer->text( 'IOSA POS\n' );
            $printer->text( 'KITCHEN ORDER\n' );
            $printer->text( '============================\n' );

            $printer->setJustification( Printer::JUSTIFY_LEFT );

            /*
            |--------------------------------------------------------------------------
            | Order Details
            |--------------------------------------------------------------------------
            */

            $printer->text(
                'Table: ' .
                ( $order->table->table_name ?? 'N/A' ) .
                '\n'
            );

            $printer->text(
                'Order #: ' .
                ( $order->id ?? '' ) .
                '\n'
            );

            $printer->text(
                'Time: ' .
                now()->format( 'd/m/Y H:i' ) .
                '\n'
            );

            $printer->text(
                '----------------------------\n'
            );

            /*
            |--------------------------------------------------------------------------
            | Items
            |--------------------------------------------------------------------------
            */

            foreach ( $order->items as $item ) {

                $printer->text(
                    "{$item->quantity} x {$item->product_name}\n"
                );

                if ( !empty( $item->notes ) ) {

                    $printer->text(
                        "NOTE: {$item->notes}\n"
                    );
                }

                $printer->text(
                    '----------------------------\n'
                );
            }

            /*
            |--------------------------------------------------------------------------
            | Footer
            |--------------------------------------------------------------------------
            */

            $printer->feed( 2 );

            $printer->setJustification(
                Printer::JUSTIFY_CENTER
            );

            $printer->text(
                '*** END OF ORDER ***\n'
            );

            $printer->feed( 3 );

            $printer->cut();

            $printer->close();

            return true;

        } catch ( \Throwable $e ) {

            \Log::error(
                'Kitchen printer error: ' .
                $e->getMessage()
            );

            return false;
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Test Print
    |--------------------------------------------------------------------------
    */

    public function testPrint( $printerConfig ): bool
 {
        try {
            $connector = new \Mike42\Escpos\PrintConnectors\NetworkPrintConnector(
                $printerConfig->ip_address,
                $printerConfig->port ?? 9100
            );

            $printer = new \Mike42\Escpos\Printer( $connector );

            $printer->setJustification( \Mike42\Escpos\Printer::JUSTIFY_CENTER );
            $printer->text( 'IOSA POS\n' );
            $printer->text( 'TEST PRINT\n' );
            $printer->text( '========================\n\n' );

            $printer->setJustification( \Mike42\Escpos\Printer::JUSTIFY_LEFT );
            $printer->text( "Printer: {$printerConfig->name}\n" );
            $printer->text( "IP: {$printerConfig->ip_address}\n" );
            $printer->text( "Port: {$printerConfig->port}\n" );
            $printer->text( 'Date: ' . now()->format( 'd/m/Y H:i' ) . '\n\n' );

            $printer->setJustification( \Mike42\Escpos\Printer::JUSTIFY_CENTER );
            $printer->text( 'Printer OK\n\n' );

            $printer->cut();
            $printer->close();

            return true;
        } catch ( \Throwable $e ) {
            \Log::error( 'Printer test failed: ' . $e->getMessage() );

            return false;
        }
    }

}