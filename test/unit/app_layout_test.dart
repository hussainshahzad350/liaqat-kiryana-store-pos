import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/res/app_layout.dart';

void main() {
  group('AppLayout.salesSidePanelWidth', () {
    test('uses the compact width below the desktop baseline', () {
      expect(AppLayout.salesSidePanelWidth(1024), 450);
    });

    test('uses progressively wider panels at desktop breakpoints', () {
      expect(AppLayout.salesSidePanelWidth(1366), 500);
      expect(AppLayout.salesSidePanelWidth(1920), 550);
      expect(AppLayout.salesSidePanelWidth(2560), 600);
    });
  });

  group('AppLayout.productGridColumnCount', () {
    test('clamps narrow layouts to the minimum column count', () {
      expect(AppLayout.productGridColumnCount(320), 4);
    });

    test('scales within the supported density range', () {
      expect(AppLayout.productGridColumnCount(900), 5);
      expect(AppLayout.productGridColumnCount(1260), 7);
    });

    test('clamps wide layouts to the maximum column count', () {
      expect(AppLayout.productGridColumnCount(3000), 8);
    });
  });
}
