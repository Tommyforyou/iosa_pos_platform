/*
|--------------------------------------------------------------------------
| Discount Utilities
|--------------------------------------------------------------------------
| Centralized POS discount calculations.
|
| Supported discounts:
| - 5%
| - 10%
| - 15%
| - 50%
| - 100%
|
| Used by:
| - billing
| - counter POS
| - receipts
| - reports
*/

/*
|--------------------------------------------------------------------------
| Calculate Discount Amount
|--------------------------------------------------------------------------
*/

double calculateDiscountAmount({
  required double subtotal,
  required double discountPercentage,
}) {
  return subtotal * (discountPercentage / 100);
}

/*
|--------------------------------------------------------------------------
| Calculate Final Total
|--------------------------------------------------------------------------
*/

double calculateFinalTotal({
  required double subtotal,
  required double discountPercentage,
}) {
  final discount = calculateDiscountAmount(
    subtotal: subtotal,
    discountPercentage: discountPercentage,
  );

  return subtotal - discount;
}

/*
|--------------------------------------------------------------------------
| VAT Included Calculation
|--------------------------------------------------------------------------
| Mauritius VAT = 15%
|
| VAT portion formula:
| VAT = total × 15 / 115
*/

double calculateVatIncluded(double total) {
  return total * 15 / 115;
}