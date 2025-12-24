import 'package:flutter/material.dart';
import 'package:liaqat_store/core/utils/logger.dart';

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
}