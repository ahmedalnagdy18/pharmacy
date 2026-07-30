import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_cubit.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_cubit.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SuppliersCubit, SuppliersState>(
    builder: (context, state) {
      final data = state is SuppliersLoaded ? state : null;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Suppliers',
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
                  label: const Text('Add supplier'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is SuppliersLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Outstanding')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: (data?.suppliers ?? const <SupplierModel>[]).map((
                      supplier,
                    ) {
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
}
