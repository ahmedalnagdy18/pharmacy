import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/expenses/presentation/cubits/expenses_cubit.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ExpensesCubit, ExpensesState>(
    builder: (context, state) {
      final items = state is ExpensesLoaded ? state.items : const [];
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  context.tr('Expenses'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => context.read<ExpensesCubit>().load(),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _addDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('Add expense')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(context.tr('Total expenses')),
                trailing: Text(
                  AppFormatters.currency.format(total),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (state is ExpensesLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.money_off_csred_outlined),
                      ),
                      title: Text(item.reason),
                      subtitle: Text(AppFormatters.dateTime.format(item.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppFormatters.currency.format(item.amount)),
                          IconButton(
                            tooltip: context.tr('Edit'),
                            onPressed: () => _editDialog(context, item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: context.tr('Delete'),
                            onPressed: () => _confirmRemove(context, item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _addDialog(BuildContext context) async {
    final form = GlobalKey<FormState>();
    final amount = TextEditingController();
    final reason = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Add expense')),
        content: SizedBox(
          width: 400,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: context.tr('Amount')),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Enter a valid amount'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reason,
                  decoration: InputDecoration(labelText: context.tr('Reason')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted)
      await context.read<ExpensesCubit>().add(
        amount: double.parse(amount.text),
        reason: reason.text,
      );
  }

  Future<void> _editDialog(BuildContext context, ExpenseModel item) async {
    final form = GlobalKey<FormState>();
    final amount = TextEditingController(text: item.amount.toString());
    final reason = TextEditingController(text: item.reason);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Edit')),
        content: SizedBox(
          width: 400,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: context.tr('Amount')),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Enter a valid amount'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reason,
                  decoration: InputDecoration(labelText: context.tr('Reason')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted)
      await context.read<ExpensesCubit>().update(
        item,
        amount: double.parse(amount.text),
        reason: reason.text,
      );
  }

  Future<void> _confirmRemove(BuildContext context, ExpenseModel item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('Delete')), content: Text('${item.reason} — ${AppFormatters.currency.format(item.amount)}'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('Cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('Delete')))],
    ));
    if (confirmed == true && context.mounted) await context.read<ExpensesCubit>().remove(item.id);
  }
}
