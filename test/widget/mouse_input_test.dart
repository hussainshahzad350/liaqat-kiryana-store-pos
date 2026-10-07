import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/theme/app_themes.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/cart_item_model.dart';
import 'package:liaqat_store/screens/sales/widgets/cart_item_row.dart';
import 'package:liaqat_store/widgets/app_mouse_input.dart';
import 'package:liaqat_store/widgets/on_screen_keyboard.dart';

Future<void> _field(
  WidgetTester tester,
  TextEditingController controller, {
  ValueChanged<String>? changed,
  bool pin = false,
  bool readOnly = false,
  String language = 'en',
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppThemes.getTheme('green', brightness, isRTL: language == 'ur'),
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (_, child) => AppMouseInput(child: child!),
    home: Scaffold(
        body: Center(
            child: SizedBox(
                width: 300,
                child: TextField(
                  key: const ValueKey('target-field'),
                  controller: controller,
                  readOnly: readOnly,
                  obscureText: pin,
                  keyboardType: pin ? TextInputType.number : TextInputType.text,
                  inputFormatters: pin
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6)
                        ]
                      : null,
                  onChanged: changed,
                )))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('target-field')));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-on-screen-keyboard')),
      kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
  expect(find.byType(OnScreenKeyboard), findsOneWidget);
}

Future<void> _keys(WidgetTester tester, String text) async {
  for (final key in text.characters) {
    await tester.tap(find.byKey(ValueKey('keyboard-key-$key')));
    await tester.pump();
  }
}

void main() {
  testWidgets('mouse keyboard uses existing field callback only on Apply',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await _field(tester, controller, changed: changes.add);
    await _open(tester);
    await _keys(tester, 'rice');
    expect(controller.text, isEmpty);
    expect(changes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('keyboard-apply')));
    await tester.pumpAndSettle();
    expect(controller.text, 'rice');
    expect(changes, ['rice']);
    await tester.enterText(find.byKey(const ValueKey('target-field')), 'flour');
    expect(changes, ['rice', 'flour']);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'PIN stays obscured, respects formatters and Cancel leaves it unchanged',
      (tester) async {
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    final changes = <String>[];
    await _field(tester, controller, pin: true, changed: changes.add);
    await _open(tester);
    final preview = find.byKey(const ValueKey('on-screen-keyboard-preview'));
    expect(tester.widget<TextField>(preview).obscureText, isTrue);
    await _keys(tester, '3456789');
    expect(tester.widget<TextField>(preview).controller!.text.length, 6);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.text, '12');
    expect(changes, isEmpty);
    await _open(tester);
    await tester.tap(find.text('Clear'));
    await _keys(tester, '2468');
    await tester.tap(find.byKey(const ValueKey('keyboard-apply')));
    await tester.pumpAndSettle();
    expect(controller.text, '2468');
    expect(changes, ['2468']);
  });
  testWidgets('read-only field cannot use mouse input', (tester) async {
    final controller = TextEditingController(text: 'Protected');
    addTearDown(controller.dispose);
    await _field(tester, controller, readOnly: true);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('open-on-screen-keyboard')))
            .onPressed,
        isNull);
    expect(controller.text, 'Protected');
  });
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      testWidgets('keyboard layout and Urdu input $language $brightness',
          (tester) async {
        tester.view.physicalSize = const Size(520, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await _field(tester, controller,
            language: language, brightness: brightness);
        await _open(tester);
        await tester.tap(find.widgetWithText(ChoiceChip, 'اردو'));
        await tester.pumpAndSettle();
        await _keys(tester, 'علی');
        await tester.tap(find.byKey(const ValueKey('keyboard-backspace')));
        await tester.tap(find.byKey(const ValueKey('keyboard-apply')));
        await tester.pumpAndSettle();
        expect(controller.text, 'عل');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('quantity arrows preserve price and use existing update callback',
      (tester) async {
    final updates = <(double, Money)>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Builder(
              builder: (context) => CartItemRow(
                    item: const CartItem(
                        id: 1,
                        nameEnglish: 'Rice',
                        nameUrdu: 'چاول',
                        currentStock: 10,
                        unitPrice: Money(10050),
                        quantity: 1,
                        total: Money(10050)),
                    index: 0,
                    isRTL: false,
                    colorScheme: Theme.of(context).colorScheme,
                    onRemove: (_) {},
                    onUpdate: (_, qty, price) => updates.add((qty, price)),
                  ))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quantity-increase-1')));
    await tester.tap(find.byKey(const ValueKey('quantity-increase-1')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(updates, [(3.0, const Money(10050))]);
    await tester.tap(find.byKey(const ValueKey('quantity-decrease-1')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(updates.last, (2.0, const Money(10050)));
    expect(tester.takeException(), isNull);
  });
}
