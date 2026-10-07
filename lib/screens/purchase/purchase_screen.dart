import '../../widgets/app_feature_theme.dart';
import '../../core/res/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/error_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_model.dart';
import '../../bloc/purchase/purchase_bloc.dart';
import '../../bloc/purchase/purchase_event.dart';
import '../../bloc/purchase/purchase_state.dart';
import '../../widgets/loading_overlay.dart';
import 'widgets/purchase_item_list_widget.dart';
import 'widgets/purchase_cart_widget.dart';
import 'dialogs/add_purchase_item_dialog.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  BuildContext? _presentationContext;
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<PurchaseBloc>().add(SubmitPurchase(
          invoiceNumber: _invoiceCtrl.text,
          notes: _notesCtrl.text,
        ));
  }

  void _cancel() {
    if (!context.mounted) return;
    Navigator.maybePop(context);
  }

  void _onProductTapped(Product p) {
    showDialog(
      context: _presentationContext ?? context,
      builder: (_) => AddPurchaseItemDialog(
        product: p,
        onConfirm: (item) {
          if (!context.mounted) return;
          context.read<PurchaseBloc>().add(AddPurchaseItem(item));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppFeatureTheme(builder: _buildFeature);

  Widget _buildFeature(BuildContext context) {
    _presentationContext = context;

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) {
            _save();
            return null;
          }),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) {
            _cancel();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: BlocListener<PurchaseBloc, PurchaseState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == PurchaseStatus.success) {
                _invoiceCtrl.clear();
                _notesCtrl.clear();
                setState(() {
                  _purchaseDate = DateTime.now();
                });

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.purchaseSavedSuccess),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              } else if (state.status == PurchaseStatus.failure) {
                if (!context.mounted) return;
                final msg = state.error != null
                    ? ErrorHandler.getLocalizedMessage(state.error!, loc)
                    : loc.unknownError;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            child: BlocBuilder<PurchaseBloc, PurchaseState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    Positioned.fill(
                        child: ColoredBox(
                            color: colorScheme.surfaceContainerLowest)),
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.surfacePadding),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double rightPanelWidth = 340;
                          if (constraints.maxWidth >= 2560) {
                            rightPanelWidth = 500;
                          } else if (constraints.maxWidth >= 1920) {
                            rightPanelWidth = 440;
                          } else if (constraints.maxWidth >= 1366) {
                            rightPanelWidth = 380;
                          }

                          return Row(
                            children: [
                              // LEFT PANEL
                              Expanded(
                                child: Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Toolbar equivalent
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 12.0),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          border: Border(
                                            bottom: BorderSide(
                                                color:
                                                    colorScheme.outlineVariant),
                                          ),
                                        ),
                                        child: Text(
                                          loc.purchaseScreenTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        child: PurchaseItemListWidget(
                                          cartItemIds: state.cartItems
                                              .map((e) => e.productId)
                                              .toList(),
                                          onProductTapped: _onProductTapped,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // DIVIDER
                              const SizedBox(width: AppTokens.contentGap),

                              // RIGHT PANEL
                              SizedBox(
                                width: rightPanelWidth,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppTokens.surfacePadding),
                                    child: PurchaseCartWidget(
                                      invoiceCtrl: _invoiceCtrl,
                                      notesCtrl: _notesCtrl,
                                      purchaseDate: _purchaseDate,
                                      onDateChanged: (val) {
                                        setState(() {
                                          _purchaseDate = val;
                                        });
                                      },
                                      onSave: _save,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (state.status == PurchaseStatus.submitting)
                      const LoadingOverlay(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
