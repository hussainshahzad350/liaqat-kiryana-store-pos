import 'package:flutter/material.dart';
import 'package:liaqat_store/core/utils/logger.dart';
import '../../l10n/app_localizations.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String tag = 'Error',
    bool showSnackbar = true,
  }) {
    AppLogger.error('$error', tag: tag);

    if (showSnackbar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getLocalizedMessage(error.toString(), AppLocalizations.of(context)!)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Converts technical error messages to user-friendly localized strings
  ///
  /// Returns the localized error message if a mapping exists,
  /// otherwise returns the original error message
  static String getLocalizedMessage(
    String? errorMessage,
    AppLocalizations loc,
  ) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return loc.unknownError;
    }

    final normalized = errorMessage.replaceFirst('Exception: ', '').trim();

    if (normalized.startsWith('CATEGORY_IN_USE:')) {
      final countText = normalized.substring('CATEGORY_IN_USE:'.length);
      final count = int.tryParse(countText) ?? 0;
      return loc.categoryInUseDeleteError(count);
    }

    if (normalized.startsWith('SUBCATEGORY_IN_USE:')) {
      final countText = normalized.substring('SUBCATEGORY_IN_USE:'.length);
      final count = int.tryParse(countText) ?? 0;
      return loc.subCategoryInUseDeleteError(count);
    }

    // Handle structured error codes
    if (normalized == 'PRODUCT_NOT_FOUND') {
      return loc.productNotFound;
    }
    if (normalized == 'PURCHASE_NOT_FOUND') {
      return loc.purchaseNotFound;
    }
    if (normalized == 'INVOICE_NOT_FOUND') {
      return loc.invoiceNotFound;
    }
    if (normalized == 'SUPPLIER_NOT_FOUND') {
      return loc.supplierNotFound;
    }
    if (normalized == 'INSUFFICIENT_STOCK_FOR_CANCELLATION') {
      return loc.insufficientStockForCancellation;
    }
    if (normalized == 'NEGATIVE_STOCK') {
      return loc.negativeStockError;
    }
    if (normalized == 'INVALID_PRICE_ADJUSTMENT') {
      return loc.invalidPriceAdjustment;
    }
    if (normalized == 'CREDIT_LIMIT_EXCEEDED') {
      return loc.creditLimitExceeded;
    }
    if (normalized == 'INVOICE_MATH_ERROR') {
      return loc.invoiceMathError;
    }
    if (normalized == 'INSUFFICIENT_STOCK') {
      return loc.insufficientStock;
    }
    if (normalized == 'PAYMENT_FAILED') {
      return loc.paymentFailed;
    }

    final errorMap = {
      'Cannot print cancelled invoice': loc.cannotPrintCancelled,
      'Phone already exists': loc.phoneExistsError,
      'Phone number is required': loc.phoneRequired,
      'Name is required': loc.nameRequired,
      'Insufficient stock': loc.insufficientStockError,
      'Out of stock': loc.outOfStockError,
      'Stock limit reached': loc.stockLimitError,
      'Product sale price cannot be negative': loc.negativePriceError,
      'Item price cannot be negative': loc.itemNegativePriceError,
      'Stock adjustment submitted': loc.stockUpdated,
      'Transaction cancelled successfully': loc.invoiceCancelledSuccess,
      'System units cannot be edited.': loc.systemUnitWarning,
      'System units cannot be deleted.': loc.systemUnitWarning,
    };

    return errorMap[normalized] ?? normalized;
  }
}
