import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/units/units_bloc.dart';
import '../../bloc/units/units_event.dart';
import '../../bloc/units/units_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/unit_model.dart';
import '../../widgets/main_layout.dart';
import '../../core/constants/desktop_dimensions.dart';
import '../../core/res/app_dimensions.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_header.dart';


class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return MainLayout(
      currentRoute: AppRoutes.units,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: loc.units,
            icon: Icons.square_foot_outlined,
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showAddUnitDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingLarge,
                      vertical: AppDimensions.spacingMedium),
                  shape: RoundedRectangleRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(loc.addItem),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesktopDimensions.cardBorderRadius),
                  side:
                      BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                color: colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesktopDimensions.spacingLarge,
                          vertical: DesktopDimensions.spacingStandard),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 60,
                              child: Text('#',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant))),
                          Expanded(
                              flex: 2,
                              child: Text(loc.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant))),
                          Expanded(
                              flex: 1,
                              child: Text('Code',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant))),
                          SizedBox(
                              width: 120,
                              child: Text('Actions',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: BlocBuilder<UnitsBloc, UnitsState>(
                        builder: (context, state) {
                          if (state is UnitsLoading) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (state is UnitsError) {
                            return Center(child: Text(state.message));
                          } else if (state is UnitsLoaded) {
                            if (state.units.isEmpty) {
                              return const Center(child: Text('No units found'));
                            }
                            return ListView.separated(
                              itemCount: state.units.length,
                              separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: colorScheme.outline.withOpacity(0.1)),
                              itemBuilder: (context, index) {
                                final unit = state.units[index];
                                return InkWell(
                                  onTap: () {
                                    if (unit.isSystem) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(loc.systemUnitWarning)),
                                      );
                                    } else {
                                      _showEditUnitDialog(context, unit);
                                    }
                                  },
                                  hoverColor:
                                      colorScheme.primary.withOpacity(0.05),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            DesktopDimensions.spacingLarge,
                                        vertical:
                                            DesktopDimensions.spacingStandard),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 60,
                                            child: Text('${index + 1}',
                                                style: TextStyle(
                                                    color: colorScheme
                                                        .onSurface))),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                margin: const EdgeInsets.only(
                                                    right: AppDimensions
                                                        .spacingStandard),
                                                decoration: BoxDecoration(
                                                  color: unit.isSystem
                                                      ? colorScheme.surfaceVariant
                                                      : colorScheme
                                                          .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppDimensions
                                                              .borderRadius),
                                                ),
                                                child: Icon(
                                                    unit.isSystem
                                                        ? Icons.lock_outline
                                                        : Icons.square_foot,
                                                    size: 18,
                                                    color: unit.isSystem
                                                        ? colorScheme
                                                            .onSurfaceVariant
                                                        : colorScheme
                                                            .onPrimaryContainer),
                                              ),
                                              Text(unit.name,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: colorScheme
                                                          .onSurface)),
                                              if (unit.isSystem)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      left: AppDimensions
                                                          .spacingMedium),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: AppDimensions
                                                              .spacingMedium,
                                                          vertical: AppDimensions
                                                              .spacingSmall),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .surfaceVariant,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppDimensions
                                                                .borderRadiusSmall),
                                                    border: Border.all(
                                                        color: colorScheme
                                                            .outline
                                                            .withOpacity(0.3)),
                                                  ),
                                                  child: Text('System',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: colorScheme
                                                              .onSurfaceVariant)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: AppDimensions
                                                      .spacingMedium,
                                                  vertical: AppDimensions
                                                      .spacingSmall),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppDimensions
                                                            .borderRadiusSmall),
                                              ),
                                              child: Text(unit.code,
                                                  style: TextStyle(
                                                      color: colorScheme
                                                          .onSecondaryContainer,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 20),
                                                color: unit.isSystem
                                                    ? colorScheme.outline
                                                        .withOpacity(0.5)
                                                    : colorScheme.primary,
                                                onPressed: unit.isSystem
                                                    ? null
                                                    : () =>
                                                        _showEditUnitDialog(
                                                            context, unit),
                                                tooltip: unit.isSystem
                                                    ? 'System Unit'
                                                    : loc.editItem,
                                                splashRadius: 20,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 20),
                                                color: unit.isSystem
                                                    ? colorScheme.outline
                                                        .withOpacity(0.5)
                                                    : colorScheme.error,
                                                onPressed: unit.isSystem
                                                    ? null
                                                    : () => _deleteUnit(
                                                        context, unit),
                                                tooltip: unit.isSystem
                                                    ? 'System Unit'
                                                    : 'Delete',
                                                splashRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showAddUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UnitsBloc>(),
        child: const UnitDialog(),
      ),
    );
  }

  void _showEditUnitDialog(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UnitsBloc>(),
        child: UnitDialog(unit: unit),
      ),
    );
  }

  void _deleteUnit(BuildContext context, Unit unit) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: TextStyle(color: colorScheme.onSurface)),
        content: Text(loc.confirmDeleteItem, style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.no, style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UnitsBloc>().add(DeleteCustomUnit(unit.id));
              Navigator.pop(context);
            },
            child: Text(loc.yesDelete),
          ),
        ],
      ),
    );
  }
}

class UnitDialog extends StatefulWidget {
  final Unit? unit;

  const UnitDialog({super.key, this.unit});

  @override
  State<UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.unit?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.unit?.code ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.unit != null;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(isEdit ? loc.editItem : loc.addItem,
          style: TextStyle(
              color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                    labelText: loc.name,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadius))),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
              TextFormField(
                controller: _codeCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                    labelText: 'Code (e.g. KG)',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadius))),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Default to 'Count' category (ID 3) for now since selector is not yet implemented
              const defaultCategory =
                  UnitCategory(id: 3, name: 'Count', isSystem: true);

              final unit = widget.unit != null
                  ? widget.unit!
                      .copyWith(name: _nameCtrl.text, code: _codeCtrl.text)
                  : Unit(
                      id: 0, // Dummy ID for new entry
                      name: _nameCtrl.text,
                      code: _codeCtrl.text,
                      category: defaultCategory);

              if (isEdit) {
                context.read<UnitsBloc>().add(UpdateCustomUnit(unit));
              } else {
                context.read<UnitsBloc>().add(AddCustomUnit(unit));
              }
              Navigator.pop(context);
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}