import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/invoice_bloc.dart';
import '../../../bloc/sales/invoice_event.dart';
import '../../../bloc/sales/invoice_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';

class CustomerSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAddCustomer;
  final Function(Customer?) onSelectCustomer;

  const CustomerSearchWidget({
    super.key,
    required this.controller,
    required this.onAddCustomer,
    required this.onSelectCustomer,
  });

  @override
  State<CustomerSearchWidget> createState() => _CustomerSearchWidgetState();
}

class _CustomerSearchWidgetState extends State<CustomerSearchWidget> {
  Timer? _customerSearchDebounce;

  @override
  void dispose() {
    _customerSearchDebounce?.cancel();
    super.dispose();
  }

  void _filterCustomers(String query) {
    _customerSearchDebounce?.cancel();
    _customerSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<InvoiceBloc>().add(CustomerSearchChanged(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = context.watch<InvoiceBloc>().state;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: loc.searchCustomerHint,
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: state.selectedCustomer != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => widget.onSelectCustomer(null),
                      )
                    : IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: widget.onAddCustomer,
                      ),
              ),
              onChanged: _filterCustomers,
            ),
            if (state.showCustomerList)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: state.filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = state.filteredCustomers[index];
                    return ListTile(
                      title: Text(customer.nameEnglish),
                      subtitle: Text(customer.contactPrimary ?? ''),
                      onTap: () => widget.onSelectCustomer(customer),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
