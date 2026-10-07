import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/utils/error_handler.dart';
import 'package:liaqat_store/l10n/app_localizations_en.dart';
import 'package:liaqat_store/l10n/app_localizations_ur.dart';

void main() {
  for (final loc in [AppLocalizationsEn(), AppLocalizationsUr()]) {
    test(
        '${loc.localeName} missing supplier has a localized validation message',
        () {
      expect(ErrorHandler.getLocalizedMessage('Please select a supplier', loc),
          loc.selectSupplier);
    });
  }
}
