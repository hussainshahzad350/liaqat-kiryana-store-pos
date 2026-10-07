import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/services/pin_auth_service.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

Future<void> settleDesktop(WidgetTester tester) async {
  // Native lifecycle focus can be suspended between harness scenarios.
  // Restore the window, without assigning focus to any individual control,
  // so real Tab traversal and shortcut assertions run in an active app.
  if (!await windowManager.isFocused()) await windowManager.focus();
  await tester.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
  expect(tester.takeException(), isNull);
}

Future<void> loginDesktop(WidgetTester tester, {String pin = '2468'}) async {
  await tester.enterText(find.byType(TextField).first, pin);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settleDesktop(tester);
  expect(find.byType(AppShell), findsOneWidget);
}

Future<void> withDesktopFixture(WidgetTester tester,
    Future<void> Function(String recoveryCode) body) async {
  sqfliteFfiInit();
  final originalPath = await databaseFactoryFfi.getDatabasesPath();
  final directory = await Directory.systemTemp.createTemp('liaqat_workflow_');
  expect(p.isWithin(Directory.systemTemp.path, directory.path), isTrue);
  await databaseFactoryFfi.setDatabasesPath(directory.path);
  SharedPreferences.setMockInitialValues(
      {'printOnSale': false, 'soundEnabled': false});
  FlutterSecureStorage.setMockInitialValues({});
  final recovery = await PinAuthService().setupPin('2468');
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
    await settleDesktop(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    tester.testTextInput.register();
    final db = await DatabaseHelper.instance.database;
    expect(p.isWithin(directory.path, db.path), isTrue);
    await body(recovery);
    // Restore closes the original connection and opens the restored database.
    final currentDb = await DatabaseHelper.instance.database;
    expect(p.isWithin(directory.path, currentDb.path), isTrue);
    expect(await currentDb.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  } finally {
    tester.testTextInput.unregister();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await DatabaseHelper.instance.close();
    await databaseFactoryFfi.setDatabasesPath(originalPath);
    await directory.delete(recursive: true);
    FlutterError.onError = previousErrorHandler;
  }
}
