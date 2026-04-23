import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';

void main() {
  late SettingsRepository repository;

  setUp(() {
    repository = SettingsRepository();
  });

  // ── getAppPreferences – default values ───────────────────────────────────

  group('getAppPreferences – default values', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns default language "en"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['language'], 'en');
    });

    test('returns default theme "green"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['theme'], 'green');
    });

    test('returns default themeMode "system"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['themeMode'], 'system');
    });

    test('returns default dateFormat "DD-MM-YYYY"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['dateFormat'], 'DD-MM-YYYY');
    });

    test('returns default currencySymbol "Rs"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['currencySymbol'], 'Rs');
    });

    test('returns default currencyPosition "before"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['currencyPosition'], 'before');
    });

    test('returns default requirePassword false', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['requirePassword'], false);
    });

    test('returns default password empty string', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['password'], '');
    });

    test('returns default autoBackupEnabled false', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['autoBackupEnabled'], false);
    });

    test('returns default backupFrequency "Daily"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['backupFrequency'], 'Daily');
    });

    test('returns default lowStockAlert true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['lowStockAlert'], true);
    });

    test('returns default dayCloseReminder true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['dayCloseReminder'], true);
    });

    test('returns default soundEnabled true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['soundEnabled'], true);
    });

    test('returns default printOnSale false', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['printOnSale'], false);
    });

    test('returns default showLogo true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showLogo'], true);
    });

    test('returns default showAddress true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showAddress'], true);
    });

    test('returns default showPhone true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showPhone'], true);
    });

    test('returns default showDateTime true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showDateTime'], true);
    });

    test('returns default showCustomer true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showCustomer'], true);
    });

    test('returns default showPayment true', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showPayment'], true);
    });

    test('returns default receiptFontSize "medium"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['receiptFontSize'], 'medium');
    });

    test('returns default paperWidth "80mm"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['paperWidth'], '80mm');
    });

    test('returns default printerType "usb"', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['printerType'], 'usb');
    });

    test('returns map with all 23 expected keys', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs.keys, containsAll([
        'language', 'theme', 'themeMode', 'dateFormat',
        'currencySymbol', 'currencyPosition',
        'requirePassword', 'password',
        'autoBackupEnabled', 'backupFrequency',
        'lowStockAlert', 'dayCloseReminder',
        'soundEnabled', 'printOnSale',
        'showLogo', 'showAddress', 'showPhone', 'showDateTime',
        'showCustomer', 'showPayment',
        'receiptFontSize', 'paperWidth', 'printerType',
      ]));
    });
  });

  // ── getAppPreferences – reads stored values ──────────────────────────────

  group('getAppPreferences – reads stored values', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'app_language': 'ur',
        'app_theme': 'blue',
        'app_theme_mode': 'dark',
        'date_format': 'MM-DD-YYYY',
        'currency_symbol': '\$',
        'currency_position': 'after',
        'require_password': true,
        'app_password': 'secret123',
        'auto_backup_enabled': true,
        'backup_frequency': 'Weekly',
        'low_stock_alert': false,
        'day_close_reminder': false,
        'soundEnabled': false,
        'printOnSale': true,
        'receipt_show_logo': false,
        'receipt_show_address': false,
        'receipt_show_phone': false,
        'receipt_show_datetime': false,
        'receipt_show_customer': false,
        'receipt_show_payment': false,
        'receipt_font_size': 'large',
        'receipt_paper_width': '58mm',
        'receipt_printer_type': 'network',
      });
    });

    test('returns stored language', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['language'], 'ur');
    });

    test('returns stored theme', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['theme'], 'blue');
    });

    test('returns stored themeMode', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['themeMode'], 'dark');
    });

    test('returns stored requirePassword', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['requirePassword'], true);
    });

    test('returns stored password', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['password'], 'secret123');
    });

    test('returns stored autoBackupEnabled', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['autoBackupEnabled'], true);
    });

    test('returns stored showLogo as false', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['showLogo'], false);
    });

    test('returns stored paperWidth', () async {
      final prefs = await repository.getAppPreferences();
      expect(prefs['paperWidth'], '58mm');
    });
  });

  // ── getAppPreferences – normalization ────────────────────────────────────

  group('getAppPreferences – lowercase normalization', () {
    test('normalizes receiptFontSize to lowercase', () async {
      SharedPreferences.setMockInitialValues({
        'receipt_font_size': 'LARGE',
      });
      final prefs = await repository.getAppPreferences();
      expect(prefs['receiptFontSize'], 'large');
    });

    test('normalizes printerType to lowercase', () async {
      SharedPreferences.setMockInitialValues({
        'receipt_printer_type': 'USB',
      });
      final prefs = await repository.getAppPreferences();
      expect(prefs['printerType'], 'usb');
    });

    test('normalizes mixed-case receiptFontSize', () async {
      SharedPreferences.setMockInitialValues({
        'receipt_font_size': 'Medium',
      });
      final prefs = await repository.getAppPreferences();
      expect(prefs['receiptFontSize'], 'medium');
    });

    test('normalizes mixed-case printerType', () async {
      SharedPreferences.setMockInitialValues({
        'receipt_printer_type': 'Network',
      });
      final prefs = await repository.getAppPreferences();
      expect(prefs['printerType'], 'network');
    });
  });

  // ── updateAppPreferences ─────────────────────────────────────────────────

  group('updateAppPreferences – selective update', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updates language key', () async {
      await repository.updateAppPreferences({'language': 'ur'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['language'], 'ur');
    });

    test('updates theme key', () async {
      await repository.updateAppPreferences({'theme': 'orange'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['theme'], 'orange');
    });

    test('updates themeMode key', () async {
      await repository.updateAppPreferences({'themeMode': 'dark'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['themeMode'], 'dark');
    });

    test('updates dateFormat key', () async {
      await repository.updateAppPreferences({'dateFormat': 'YYYY-MM-DD'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['dateFormat'], 'YYYY-MM-DD');
    });

    test('updates currencySymbol key', () async {
      await repository.updateAppPreferences({'currencySymbol': '€'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['currencySymbol'], '€');
    });

    test('updates currencyPosition key', () async {
      await repository.updateAppPreferences({'currencyPosition': 'after'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['currencyPosition'], 'after');
    });

    test('updates requirePassword key', () async {
      await repository.updateAppPreferences({'requirePassword': true});
      final prefs = await repository.getAppPreferences();
      expect(prefs['requirePassword'], true);
    });

    test('updates password key', () async {
      await repository.updateAppPreferences({'password': 'newpass'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['password'], 'newpass');
    });

    test('updates autoBackupEnabled key', () async {
      await repository.updateAppPreferences({'autoBackupEnabled': true});
      final prefs = await repository.getAppPreferences();
      expect(prefs['autoBackupEnabled'], true);
    });

    test('updates backupFrequency key', () async {
      await repository.updateAppPreferences({'backupFrequency': 'Weekly'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['backupFrequency'], 'Weekly');
    });

    test('updates lowStockAlert key', () async {
      await repository.updateAppPreferences({'lowStockAlert': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['lowStockAlert'], false);
    });

    test('updates dayCloseReminder key', () async {
      await repository.updateAppPreferences({'dayCloseReminder': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['dayCloseReminder'], false);
    });

    test('updates soundEnabled key', () async {
      await repository.updateAppPreferences({'soundEnabled': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['soundEnabled'], false);
    });

    test('updates printOnSale key', () async {
      await repository.updateAppPreferences({'printOnSale': true});
      final prefs = await repository.getAppPreferences();
      expect(prefs['printOnSale'], true);
    });
  });

  group('updateAppPreferences – receipt options', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updates showLogo key', () async {
      await repository.updateAppPreferences({'showLogo': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showLogo'], false);
    });

    test('updates showAddress key', () async {
      await repository.updateAppPreferences({'showAddress': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showAddress'], false);
    });

    test('updates showPhone key', () async {
      await repository.updateAppPreferences({'showPhone': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showPhone'], false);
    });

    test('updates showDateTime key', () async {
      await repository.updateAppPreferences({'showDateTime': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showDateTime'], false);
    });

    test('updates showCustomer key', () async {
      await repository.updateAppPreferences({'showCustomer': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showCustomer'], false);
    });

    test('updates showPayment key', () async {
      await repository.updateAppPreferences({'showPayment': false});
      final prefs = await repository.getAppPreferences();
      expect(prefs['showPayment'], false);
    });

    test('updates receiptFontSize key', () async {
      await repository.updateAppPreferences({'receiptFontSize': 'small'});
      final prefs = await repository.getAppPreferences();
      // Note: stored as-is, but getAppPreferences normalizes on read
      expect(prefs['receiptFontSize'], 'small');
    });

    test('updates paperWidth key', () async {
      await repository.updateAppPreferences({'paperWidth': 'A4'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['paperWidth'], 'A4');
    });

    test('updates printerType key', () async {
      await repository.updateAppPreferences({'printerType': 'pdf'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['printerType'], 'pdf');
    });
  });

  group('updateAppPreferences – partial updates and isolation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'app_theme': 'green',
        'soundEnabled': true,
      });
    });

    test('does not affect other keys when updating only one', () async {
      await repository.updateAppPreferences({'theme': 'blue'});
      final prefs = await repository.getAppPreferences();
      expect(prefs['theme'], 'blue');
      expect(prefs['language'], 'en'); // unchanged
      expect(prefs['soundEnabled'], true); // unchanged
    });

    test('updates multiple keys in a single call', () async {
      await repository.updateAppPreferences({
        'language': 'ur',
        'theme': 'orange',
        'soundEnabled': false,
      });
      final prefs = await repository.getAppPreferences();
      expect(prefs['language'], 'ur');
      expect(prefs['theme'], 'orange');
      expect(prefs['soundEnabled'], false);
    });

    test('ignores unknown keys without error', () async {
      // Should complete without throwing
      await expectLater(
        repository.updateAppPreferences({'unknownKey': 'value', 'anotherUnknown': 42}),
        completes,
      );
    });

    test('empty map updates nothing', () async {
      await repository.updateAppPreferences({});
      final prefs = await repository.getAppPreferences();
      expect(prefs['language'], 'en');
      expect(prefs['theme'], 'green');
    });

    // Regression: default theme changed from 'lightGreen' to 'green' in this PR
    test('default theme is "green" not "lightGreen"', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await repository.getAppPreferences();
      expect(prefs['theme'], 'green');
      expect(prefs['theme'], isNot('lightGreen'));
    });
  });
}