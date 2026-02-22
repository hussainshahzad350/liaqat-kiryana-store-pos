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
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
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
      return 'An unknown error occurred';
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
    };

    return errorMap[errorMessage] ?? errorMessage;
  }
}
