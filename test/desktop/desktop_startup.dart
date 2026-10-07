import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/services/pin_auth_service.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/sales_screen.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'package:liaqat_store/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in [
    (
      name: 'English startup and PIN login',
      language: 'en',
      size: const Size(1366, 768)
    ),
    (name: 'Urdu sales layout', language: 'ur', size: const Size(1366, 768)),
    (name: 'minimum Windows size', language: 'en', size: const Size(1024, 720)),
    (
      name: 'Urdu minimum Windows size',
      language: 'ur',
      size: const Size(1024, 720)
    ),
  ]) {
    testWidgets(scenario.name, (tester) async {
      sqfliteFfiInit();
      final originalPath = await databaseFactoryFfi.getDatabasesPath();
      final directory =
          await Directory.systemTemp.createTemp('liaqat_desktop_');
      expect(p.isWithin(Directory.systemTemp.path, directory.path), isTrue);
      await databaseFactoryFfi.setDatabasesPath(directory.path);
      // Startup and authentication use memory stores so the installed user's
      // preferences, credentials and lockout state cannot be read or written.
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await PinAuthService().setupPin('2468');
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        previousErrorHandler?.call(details);
      };
      try {
        app.main();
        for (var attempt = 0;
            attempt < 100 && find.byType(LoginScreen).evaluate().isEmpty;
            attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate, const Duration(seconds: 20));
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.testTextInput.register();
        await tester.enterText(find.byType(TextField).first, '2468');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(SalesScreen), findsOneWidget);
        final db = await DatabaseHelper.instance.database;
        expect(p.isWithin(directory.path, db.path), isTrue);
        expect(await db.getVersion(), 5);
        expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
        expect(tester.takeException(), isNull);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(scenario.language));
        await tester.pumpAndSettle();
        expect(Directionality.of(tester.element(find.byType(SalesScreen))),
            scenario.language == 'ur' ? TextDirection.rtl : TextDirection.ltr);
        expect(tester.takeException(), isNull);
        await windowManager.setSize(scenario.size);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final loc =
            AppLocalizations.of(tester.element(find.byType(SalesScreen)))!;
        expect(find.text(loc.cartEmpty).hitTestable(), findsOneWidget);
        final boundary = tester.renderObject<RenderRepaintBoundary>(find
            .ancestor(
                of: find.byType(AppShell),
                matching: find.byType(RepaintBoundary))
            .first);
        final screenshot = await boundary.toImage();
        try {
          final bytes =
              await screenshot.toByteData(format: ui.ImageByteFormat.png);
          final output = Directory('build/desktop-layout-review');
          await output.create(recursive: true);
          final name = scenario.name.toLowerCase().replaceAll(' ', '-');
          await File(p.join(output.path, '$name.png')).writeAsBytes(bytes!
              .buffer
              .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        } finally {
          screenshot.dispose();
        }
      } finally {
        tester.testTextInput.unregister();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await DatabaseHelper.instance.close();
        await databaseFactoryFfi.setDatabasesPath(originalPath);
        await directory.delete(recursive: true);
        FlutterError.onError = previousErrorHandler;
      }
    });
  }
}
