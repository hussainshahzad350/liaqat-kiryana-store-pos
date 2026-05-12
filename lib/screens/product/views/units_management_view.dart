import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/units/units_bloc.dart';
import '../../../bloc/units/units_event.dart';
import '../../../core/repositories/units_repository.dart';
import '../../units/units_screen.dart';

class UnitsManagementView extends StatefulWidget {
  const UnitsManagementView({super.key});

  @override
  State<UnitsManagementView> createState() => _UnitsManagementViewState();
}

class _UnitsManagementViewState extends State<UnitsManagementView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (context) =>
          UnitsBloc(context.read<UnitsRepository>())..add(LoadUnits()),
      child: const UnitsScreen(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
