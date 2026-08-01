import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_cubit.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';
import 'package:pharmacy/widgets/date_filter_bar.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _search = TextEditingController();
  DateFilter _dateFilter = DateFilter.allTime;
  DateTime? _customDate;
  bool _showDebtorsOnly = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CustomersCubit, CustomersState>(
    builder: (context, state) {
      final data = state is CustomersLoaded ? state : null;
      final q = _search.text.toLowerCase();
      final customers = (data?.customers ?? const <CustomerModel>[])
          .where(
            (c) =>
                q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q),
          )
          .where((customer) {
            final debts =
                data?.debts
                    .where((debt) => debt.customerId == customer.id)
                    .toList() ??
                [];
            final payments =
                data?.payments
                    .where((payment) => payment.customerId == customer.id)
                    .toList() ??
                [];
            final hasDebt = debts.any(
              (debt) =>
                  debt.status == DebtStatus.pending && debt.remainingAmount > 0,
            );
            final hasActivity =
                _dateFilter == DateFilter.allTime ||
                debts.any(
                  (debt) => matchesDateFilter(
                    debt.createdAt,
                    _dateFilter,
                    _customDate,
                  ),
                ) ||
                payments.any(
                  (payment) => matchesDateFilter(
                    payment.date,
                    _dateFilter,
                    _customDate,
                  ),
                );
            return (!_showDebtorsOnly || hasDebt) && hasActivity;
          })
          .toList();
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  context.tr('Customers'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => context.read<CustomersCubit>().load(),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _customerDialog(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(context.tr('Add customer')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by customer name or phone',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DateFilterBar(
                    value: _dateFilter,
                    customDate: _customDate,
                    onChanged: (selection) => setState(() {
                      _dateFilter = selection.filter;
                      _customDate = selection.customDate;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Has outstanding debt'),
                  selected: _showDebtorsOnly,
                  onSelected: (selected) =>
                      setState(() => _showDebtorsOnly = selected),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state is CustomersLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(context.tr('Customers'))),
                      DataColumn(label: Text(context.tr('Phone'))),
                      DataColumn(
                        label: Text(context.tr('Current debt')),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(context.tr('Unpaid invoices')),
                        numeric: true,
                      ),
                      DataColumn(label: Text(context.tr('Last payment'))),
                      DataColumn(label: Text(context.tr('Actions'))),
                    ],
                    rows: customers.map((customer) {
                      final debts =
                          data?.debts
                              .where((d) => d.customerId == customer.id)
                              .toList() ??
                          [];
                      final payments =
                          data?.payments
                              .where((p) => p.customerId == customer.id)
                              .toList() ??
                          [];
                      final open = debts
                          .where((d) => d.status == DebtStatus.pending)
                          .toList();
                      final total = open.fold<double>(
                        0,
                        (sum, d) => sum + d.remainingAmount,
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(customer.name)),
                          DataCell(Text(customer.phone)),
                          DataCell(Text(AppFormatters.currency.format(total))),
                          DataCell(Text('${open.length}')),
                          DataCell(
                            Text(
                              payments.isEmpty
                                  ? '-'
                                  : AppFormatters.date.format(
                                      payments.first.date,
                                    ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'View details',
                                  onPressed: () => _details(context, customer),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Record payment',
                                  onPressed: open.isEmpty
                                      ? null
                                      : () => _paymentDialog(
                                          context,
                                          customer,
                                          open,
                                        ),
                                  icon: const Icon(Icons.payments_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _customerDialog(
                                    context,
                                    customer: customer,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => context
                                      .read<CustomersCubit>()
                                      .remove(customer.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  Future<void> _customerDialog(
    BuildContext context, {
    CustomerModel? customer,
  }) async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: customer?.name);
    final phone = TextEditingController(text: customer?.phone);
    final address = TextEditingController(text: customer?.address);
    final notes = TextEditingController(text: customer?.notes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(customer == null ? 'Add customer' : 'Edit customer'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(d, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted)
      await context.read<CustomersCubit>().save(
        id: customer?.id,
        name: name.text,
        phone: phone.text,
        address: address.text,
        notes: notes.text,
      );
  }

  Future<void> _paymentDialog(
    BuildContext context,
    CustomerModel customer,
    List<CustomerDebtModel> debts,
  ) async {
    String debtId = debts.first.id;
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Record payment — ${customer.name}'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: debtId,
                  items: debts
                      .map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text(
                            '${AppFormatters.invoiceNumber(x.invoiceId)} • ${AppFormatters.currency.format(x.remainingAmount)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (x) => debtId = x!,
                  decoration: const InputDecoration(labelText: 'Invoice'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? 'Enter a valid amount'
                      : double.parse(v!) <= 0
                      ? 'Amount must be greater than zero'
                      : double.parse(v) >
                            debts
                                .firstWhere((debt) => debt.id == debtId)
                                .remainingAmount
                      ? 'Maximum payment is ${AppFormatters.currency.format(debts.firstWhere((debt) => debt.id == debtId).remainingAmount)}'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(d, true);
            },
            child: const Text('Record payment'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CustomersCubit>().recordPayment(
        customerId: customer.id,
        debtId: debtId,
        amount: double.parse(amount.text),
      );
      if (context.mounted) {
        await context.read<SalesCubit>().load();
      }
    }
  }

  void _details(BuildContext context, CustomerModel customer) {
    final state = context.read<CustomersCubit>().state;
    if (state is! CustomersLoaded) return;
    final debts = state.debts.where((x) => x.customerId == customer.id);
    final payments = state.payments.where((x) => x.customerId == customer.id);
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(customer.name),
        content: SizedBox(
          width: 560,
          height: 400,
          child: ListView(
            children: [
              Text(
                '${customer.phone}${customer.address.isEmpty ? '' : ' • ${customer.address}'}',
              ),
              const SizedBox(height: 16),
              Text(
                'Outstanding debts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...debts.map(
                (x) => ListTile(
                  title: Text(AppFormatters.invoiceNumber(x.invoiceId)),
                  subtitle: Text(x.status),
                  trailing: Text(
                    AppFormatters.currency.format(x.remainingAmount),
                  ),
                ),
              ),
              const Divider(),
              Text(
                'Payment history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...payments.map(
                (x) => ListTile(
                  title: Text(AppFormatters.currency.format(x.amount)),
                  subtitle: Text(AppFormatters.dateTime.format(x.date)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
