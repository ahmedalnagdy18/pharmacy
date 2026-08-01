import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_cubit.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_cubit.dart';
import 'package:pharmacy/widgets/date_filter_bar.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  DateFilter _dateFilter = DateFilter.allTime;
  DateTime? _customDate;
  bool _showDebtorsOnly = false;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SuppliersCubit, SuppliersState>(
    builder: (context, state) {
      final data = state is SuppliersLoaded ? state : null;
      final suppliers = (data?.suppliers ?? const <SupplierModel>[]).where((
        supplier,
      ) {
        final debts =
            data?.debts
                .where((debt) => debt.supplierId == supplier.id)
                .toList() ??
            [];
        final payments =
            data?.payments
                .where((payment) => payment.supplierId == supplier.id)
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
                debt.date,
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
      }).toList();
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  context.tr('Suppliers'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => context.read<SuppliersCubit>().load(),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _dialog(context),
                  icon: const Icon(Icons.add_business_outlined),
                  label: Text(context.tr('Add supplier')),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            if (state is SuppliersLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(context.tr('Suppliers'))),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text(context.tr('Phone'))),
                      DataColumn(label: Text(context.tr('Outstanding'))),
                      DataColumn(label: Text(context.tr('Actions'))),
                    ],
                    rows: suppliers.map((supplier) {
                      final debts = data!.debts
                          .where(
                            (d) =>
                                d.supplierId == supplier.id &&
                                d.status == DebtStatus.pending,
                          )
                          .toList();
                      final outstanding = debts.fold<double>(
                        0,
                        (sum, d) => sum + d.remainingAmount,
                      );
                      return DataRow(
                        cells: [
                          DataCell(Text(supplier.name)),
                          DataCell(Text(supplier.company)),
                          DataCell(Text(supplier.phone)),
                          DataCell(
                            Text(AppFormatters.currency.format(outstanding)),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'View details',
                                  onPressed: () => _details(context, supplier),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Record payment',
                                  onPressed: debts.isEmpty
                                      ? null
                                      : () =>
                                            _payment(context, supplier, debts),
                                  icon: const Icon(Icons.payments_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _dialog(context, supplier: supplier),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => context
                                      .read<SuppliersCubit>()
                                      .remove(supplier.id),
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
  Future<void> _dialog(BuildContext context, {SupplierModel? supplier}) async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: supplier?.name);
    final phone = TextEditingController(text: supplier?.phone);
    final company = TextEditingController(text: supplier?.company);
    final notes = TextEditingController(text: supplier?.notes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(supplier == null ? 'Add supplier' : 'Edit supplier'),
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
                  controller: company,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
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
      await context.read<SuppliersCubit>().save(
        id: supplier?.id,
        name: name.text,
        phone: phone.text,
        company: company.text,
        notes: notes.text,
      );
  }

  Future<void> _payment(
    BuildContext context,
    SupplierModel supplier,
    List<SupplierDebtModel> debts,
  ) async {
    String debtId = debts.first.id;
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Record payment — ${supplier.name}'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: debtId,
                  isExpanded: true,
                  items: debts
                      .map(
                        (debt) => DropdownMenuItem(
                          value: debt.id,
                          child: Text(
                            'Purchase #${debt.purchaseId.substring(0, 8)} • ${AppFormatters.currency.format(debt.remainingAmount)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (x) => debtId = x!,
                  decoration: const InputDecoration(labelText: 'Purchase'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    final selectedDebt = debts.firstWhere(
                      (debt) => debt.id == debtId,
                    );
                    if (amount == null || !amount.isFinite)
                      return 'Enter a valid amount';
                    if (amount <= 0) return 'Amount must be greater than zero';
                    if (amount > selectedDebt.remainingAmount)
                      return 'Maximum is ${AppFormatters.currency.format(selectedDebt.remainingAmount)}';
                    return null;
                  },
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
    final value = double.tryParse(amount.text);
    if (ok == true && value != null && context.mounted) {
      await context.read<SuppliersCubit>().recordPayment(
        supplierId: supplier.id,
        debtId: debtId,
        amount: value,
      );
      if (context.mounted) await context.read<PurchasesCubit>().load();
    }
  }

  void _details(BuildContext context, SupplierModel supplier) {
    final state = context.read<SuppliersCubit>().state;
    if (state is! SuppliersLoaded) return;
    final debts = state.debts.where((debt) => debt.supplierId == supplier.id);
    final payments = state.payments.where(
      (payment) => payment.supplierId == supplier.id,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(supplier.name),
        content: SizedBox(
          width: 560,
          height: 400,
          child: ListView(
            children: [
              Text(
                '${supplier.company}${supplier.phone.isEmpty ? '' : ' • ${supplier.phone}'}',
              ),
              const SizedBox(height: 16),
              Text(
                'Outstanding debts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...debts.map(
                (debt) => ListTile(
                  title: Text('Purchase #${debt.purchaseId.substring(0, 8)}'),
                  subtitle: Text(
                    '${debt.status} • ${AppFormatters.dateTime.format(debt.date)}',
                  ),
                  trailing: Text(
                    AppFormatters.currency.format(debt.remainingAmount),
                  ),
                ),
              ),
              const Divider(),
              Text(
                'Payment history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...payments.map(
                (payment) => ListTile(
                  title: Text(AppFormatters.currency.format(payment.amount)),
                  subtitle: Text(AppFormatters.dateTime.format(payment.date)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
