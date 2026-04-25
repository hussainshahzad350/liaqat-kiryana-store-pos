import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/bloc/settings/settings_cubit.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/screens/settings/widgets/settings_tile.dart';

// MockCubit from bloc_test avoids the need to manually stub stream methods.
class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

/// Wraps [child] in a MaterialApp with localization and the provided cubit.
Widget buildSettingsApp({
  required SettingsCubit cubit,
  Locale locale = const Locale('en'),
}) {
  return BlocProvider<SettingsCubit>.value(
    value: cubit,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const Scaffold(body: SettingsView()),
    ),
  );
}

void main() {
  late MockSettingsCubit cubit;

  setUp(() {
    cubit = MockSettingsCubit();
    // Default state: dashboard, not loading
    when(() => cubit.state).thenReturn(SettingsState());
  });

  // Set a consistent screen size for grid layout tests
  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // ── Dashboard view ────────────────────────────────────────────────────────

  group('SettingsView – dashboard', () {
    testWidgets('shows Settings title in header when on dashboard',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('shows all 5 category tiles in dashboard', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsTile), findsNWidgets(5));
    });

    testWidgets('does not show back button on dashboard', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows Shop Profile tile', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Shop Profile'), findsOneWidget);
    });

    testWidgets('shows Backup tile', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Backup'), findsOneWidget);
    });

    testWidgets('shows About tile', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });
  });

  // ── Non-dashboard views ───────────────────────────────────────────────────

  group('SettingsView – non-dashboard category', () {
    testWidgets('shows back button when category is not dashboard',
        (tester) async {
      setDesktopSize(tester);
      when(() => cubit.state).thenReturn(
        SettingsState(selectedCategory: SettingsCategory.profile),
      );
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls selectCategory(dashboard) when back button tapped',
        (tester) async {
      setDesktopSize(tester);
      when(() => cubit.state).thenReturn(
        SettingsState(selectedCategory: SettingsCategory.backup),
      );
      when(() => cubit.selectCategory(any())).thenReturn(null);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      verify(() => cubit.selectCategory(SettingsCategory.dashboard)).called(1);
    });

    testWidgets('does not show dashboard grid when category is profile',
        (tester) async {
      setDesktopSize(tester);
      when(() => cubit.state).thenReturn(
        SettingsState(selectedCategory: SettingsCategory.profile),
      );
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
    });
  });

  // ── LoadingOverlay ────────────────────────────────────────────────────────

  group('LoadingOverlay', () {
    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      setDesktopSize(tester);
      when(() => cubit.state).thenReturn(
        SettingsState(isLoading: true),
      );
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pump(); // Don't settle — we want to see loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides CircularProgressIndicator when isLoading is false',
        (tester) async {
      setDesktopSize(tester);
      when(() => cubit.state).thenReturn(
        SettingsState(isLoading: false),
      );
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ── Tile tap navigates to category ───────────────────────────────────────

  group('SettingsView – tile navigation', () {
    testWidgets('tapping a SettingsTile calls selectCategory', (tester) async {
      setDesktopSize(tester);
      when(() => cubit.selectCategory(any())).thenReturn(null);
      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Tap the first SettingsTile (Shop Profile)
      await tester.tap(find.byType(SettingsTile).first);
      await tester.pump();

      verify(() => cubit.selectCategory(any())).called(1);
    });
  });

  // ── Snackbar messages ─────────────────────────────────────────────────────

  group('SettingsView – error and success messages', () {
    testWidgets('shows error snackbar when errorMessage is emitted',
        (tester) async {
      setDesktopSize(tester);

      // Start with no error
      when(() => cubit.state).thenReturn(SettingsState());
      when(() => cubit.clearMessages()).thenReturn(null);

      // Emit state with error
      whenListen(
        cubit,
        Stream.fromIterable([
          SettingsState(errorMessage: 'Something went wrong'),
        ]),
        initialState: SettingsState(),
      );

      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pump(); // trigger listener

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows success snackbar when successMessage is emitted',
        (tester) async {
      setDesktopSize(tester);

      when(() => cubit.state).thenReturn(SettingsState());
      when(() => cubit.clearMessages()).thenReturn(null);

      whenListen(
        cubit,
        Stream.fromIterable([
          SettingsState(successMessage: 'Profile updated successfully'),
        ]),
        initialState: SettingsState(),
      );

      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pump();

      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    testWidgets('calls clearMessages after showing error', (tester) async {
      setDesktopSize(tester);

      when(() => cubit.state).thenReturn(SettingsState());
      when(() => cubit.clearMessages()).thenReturn(null);

      whenListen(
        cubit,
        Stream.fromIterable([
          SettingsState(errorMessage: 'Test error'),
        ]),
        initialState: SettingsState(),
      );

      await tester.pumpWidget(buildSettingsApp(cubit: cubit));
      await tester.pump();

      verify(() => cubit.clearMessages()).called(greaterThanOrEqualTo(1));
    });
  });
}
