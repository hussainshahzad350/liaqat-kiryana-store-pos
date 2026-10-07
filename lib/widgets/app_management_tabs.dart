import 'package:flutter/material.dart';
import '../core/res/app_tokens.dart';

/// Shared management frame; feature views retain their own providers/lifetimes.
class AppManagementTabs extends StatelessWidget {
  const AppManagementTabs(
      {super.key,
      required this.title,
      required this.labels,
      required this.views,
      this.initialIndex = 0});
  final String title;
  final List<String> labels;
  final List<Widget> views;
  final int initialIndex;
  @override
  Widget build(BuildContext context) {
    assert(labels.length == views.length);
    return DefaultTabController(
        length: views.length,
        initialIndex: initialIndex,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.surfacePadding, vertical: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        header: true,
                        label: title,
                        child: const SizedBox.shrink()),
                    TabBar(tabs: [
                      for (final label in labels)
                        Tab(
                            height:
                                Directionality.of(context) == TextDirection.rtl
                                    ? 48
                                    : AppTokens.controlMinHeight,
                            text: label)
                    ]),
                  ])),
          Expanded(child: TabBarView(children: views)),
        ]));
  }
}
