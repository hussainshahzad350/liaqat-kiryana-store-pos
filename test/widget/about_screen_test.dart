import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/about/about_screen.dart';

void main() {
  testWidgets('AboutScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('ur'),
        ],
        home: AboutScreen(),
      ),
    );

    // Verify main title
    expect(find.text('ایپ کے بارے میں'), findsOneWidget);
    
    // Verify version
    expect(find.text('ورژن: 1.0.0'), findsOneWidget);
    
    // Verify sections
    expect(find.text('تکنیکی معلومات'), findsOneWidget);
    expect(find.text('ایپ کی خصوصیات'), findsOneWidget);
  });
}
