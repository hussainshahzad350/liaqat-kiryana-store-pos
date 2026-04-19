import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaqat_store/core/res/app_tokens.dart';
import '../../bloc/units/units_bloc.dart';
import '../../bloc/units/units_event.dart';
import '../../bloc/units/units_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/unit_model.dart';
import '../../core/repositories/units_repository.dart';
import '../../core/utils/error_handler.dart';
import 'dialogs/add_unit_dialog.dart';
import 'dialogs/edit_unit_dialog.dart';
import 'dialogs/delete_unit_dialog.dart';
import 'widgets/unit_category_section.dart';

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

    return BlocConsumer<UnitsBloc, UnitsState>(
      listener: (context, state) {
        if (state is UnitsError) {
          ErrorHandler.handleError(context, state.message, tag: 'Units');
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.unitsManagement,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: state is UnitsLoaded 
                      ? () => _showAddUnitDialog(context, state) 
                      : null,
                    icon: const Icon(Icons.add),
                    label: Text(loc.addItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingLarge),

              // Content
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UnitsState state) {
    if (state is UnitsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is UnitsLoaded) {
      if (state.categories.isEmpty) {
        final loc = AppLocalizations.of(context)!;
        return Center(child: Text(loc.noCategoriesFound));
      }

      return ListView.builder(
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final category = state.categories[index];
          final units = state.unitsByCategory[category.id] ?? [];
          final baseUnit = state.baseUnitByCategory[category.id];

          return UnitCategorySection(
            category: category,
            units: units,
            baseUnit: baseUnit,
            onEdit: (unit) => _showEditUnitDialog(context, unit, state),
            onDelete: (unit) => _showDeleteUnitDialog(context, unit),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showAddUnitDialog(BuildContext context, UnitsLoaded state) {
    showDialog(
      context: context,
      builder: (_) => AddUnitDialog(
        categories: state.categories,
        allUnits: state.units,
        onSave: (unit) {
          context.read<UnitsBloc>().add(AddCustomUnit(unit));
        },
      ),
    );
  }

  void _showEditUnitDialog(BuildContext context, Unit unit, UnitsLoaded state) {
    showDialog(
      context: context,
      builder: (_) => EditUnitDialog(
        unit: unit,
        categories: state.categories,
        allUnits: state.units,
        onSave: (updatedUnit) {
          context.read<UnitsBloc>().add(UpdateCustomUnit(updatedUnit));
        },
      ),
    );
  }

  void _showDeleteUnitDialog(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (_) => DeleteUnitDialog(
        unit: unit,
        repository: context.read<UnitsRepository>(),
        onDeleteConfirmed: () {
          context.read<UnitsBloc>().add(DeleteCustomUnit(unit.id));
        },
      ),
    );
  }
}
