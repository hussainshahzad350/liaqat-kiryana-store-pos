import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/res/app_layout.dart';

void main() {
  group('AppLayout.salesSidePanelWidth', () {
    test('keeps the cart usable in constrained panes', () {
      expect(AppLayout.salesSidePanelWidth(700), 360);
      expect(AppLayout.salesSidePanelWidth(900), 378);
    });

    test('allocates cart space from actual pane width and caps wide panes', () {
      expect(AppLayout.salesSidePanelWidth(1100), 462);
      expect(AppLayout.salesSidePanelWidth(1920), 600);
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
