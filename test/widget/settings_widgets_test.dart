import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/screens/settings/widgets/info_item.dart';
import 'package:liaqat_store/screens/settings/widgets/option_switch.dart';
import 'package:liaqat_store/screens/settings/widgets/setting_section.dart';
import 'package:liaqat_store/screens/settings/widgets/settings_tile.dart';

// Helper to wrap a widget in a minimal MaterialApp for testing.
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  // ── InfoItem ─────────────────────────────────────────────────────────────

  group('InfoItem', () {
    testWidgets('renders label and value texts', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const InfoItem(label: 'Total Items', value: '42'),
      ));
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders without optional icon when icon is null', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const InfoItem(label: 'DB Size', value: '1.5 MB'),
      ));
      expect(find.byType(Icon), findsNothing);
      expect(find.text('DB Size'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const InfoItem(
          label: 'Version',
          value: '1.0.0',
          icon: Icons.info_outline,
        ),
      ));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('label and value are laid out in a Row', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const InfoItem(label: 'Products', value: '100'),
      ));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders empty string value without error', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const InfoItem(label: 'Address', value: ''),
      ));
      expect(find.text('Address'), findsOneWidget);
    });
  });

  // ── OptionSwitch ──────────────────────────────────────────────────────────

  group('OptionSwitch', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Show Logo',
          value: true,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Show Logo'), findsOneWidget);
    });

    testWidgets('renders a Switch widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Sound',
          value: false,
          onChanged: (_) {},
        ),
      ));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch has correct initial value when true', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Feature',
          value: true,
          onChanged: (_) {},
        ),
      ));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('switch has correct initial value when false', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Feature',
          value: false,
          onChanged: (_) {},
        ),
      ));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? changedTo;
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Toggle Me',
          value: false,
          onChanged: (v) => changedTo = v,
        ),
      ));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(changedTo, true);
    });

    testWidgets('renders optional subtitle when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Auto Backup',
          subtitle: 'Backs up daily',
          value: true,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Auto Backup'), findsOneWidget);
      expect(find.text('Backs up daily'), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'Print on Sale',
          value: false,
          onChanged: (_) {},
        ),
      ));
      // Only title text should be present
      expect(find.text('Print on Sale'), findsOneWidget);
      // No second text widget from subtitle
      expect(find.byType(ListTile), findsOneWidget);
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.subtitle, isNull);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'With Icon',
          value: true,
          onChanged: (_) {},
          icon: Icons.notifications_outlined,
        ),
      ));
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('no leading icon when icon is null', (tester) async {
      await tester.pumpWidget(buildTestApp(
        OptionSwitch(
          title: 'No Icon',
          value: true,
          onChanged: (_) {},
        ),
      ));
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
    });
  });

  // ── SettingSection ────────────────────────────────────────────────────────

  group('SettingSection', () {
    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'Security',
          child: Text('section content'),
        ),
      ));
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'Security',
          child: Text('child content here'),
        ),
      ));
      expect(find.text('child content here'), findsOneWidget);
    });

    testWidgets('renders optional icon when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'Security',
          icon: Icons.security_outlined,
          child: SizedBox.shrink(),
        ),
      ));
      expect(find.byIcon(Icons.security_outlined), findsOneWidget);
    });

    testWidgets('does not render icon when not provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'No Icon Section',
          child: SizedBox.shrink(),
        ),
      ));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('wraps content in a Card', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'Card Section',
          child: SizedBox.shrink(),
        ),
      ));
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders a Divider between title and child', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SettingSection(
          title: 'With Divider',
          child: Text('body'),
        ),
      ));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('can render complex child widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingSection(
          title: 'Complex',
          child: Column(
            children: const [
              Text('item 1'),
              Text('item 2'),
            ],
          ),
        ),
      ));
      expect(find.text('item 1'), findsOneWidget);
      expect(find.text('item 2'), findsOneWidget);
    });
  });

  // ── SettingsTile ──────────────────────────────────────────────────────────

  group('SettingsTile', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.store_outlined,
          title: 'Shop Profile',
          subtitle: 'Store Name, Address',
          onTap: () {},
        ),
      ));
      expect(find.text('Shop Profile'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.store_outlined,
          title: 'Shop Profile',
          subtitle: 'Store Name, Address, Contact',
          onTap: () {},
        ),
      ));
      expect(find.text('Store Name, Address, Contact'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.backup_outlined,
          title: 'Backup',
          subtitle: 'Manage backups',
          onTap: () {},
        ),
      ));
      expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.settings_outlined,
          title: 'Preferences',
          subtitle: 'Language, Theme',
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('renders inside a Card', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version',
          onTap: () {},
        ),
      ));
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('icon size is 48', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SettingsTile(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          subtitle: 'Printer settings',
          onTap: () {},
        ),
      ));
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.size, 48);
    });
  });
}