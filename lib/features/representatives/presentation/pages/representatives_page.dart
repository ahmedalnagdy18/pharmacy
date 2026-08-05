import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';
import 'package:pharmacy/features/representatives/presentation/widgets/representative_dialog.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_cubit.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_state.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representative_collections_cubit.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

class RepresentativesPage extends StatelessWidget {
  const RepresentativesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepresentativesCubit, RepresentativesState>(
      builder: (context, state) {
        final representatives = state is RepresentativesLoaded
            ? state.representatives
            : const <RepresentativeModel>[];
        final inventoryState = context
            .watch<RepresentativeInventoryCubit>()
            .state;
        final productsState = context.watch<ProductsCubit>().state;
        final inventory = inventoryState is RepresentativeInventoryLoaded
            ? inventoryState.inventory
            : const <RepresentativeInventoryModel>[];
        final products = productsState is ProductsLoaded
            ? {
                for (final product in productsState.products)
                  product.id: product,
              }
            : const <String, MedicineModel>{};
        final salesState = context.watch<SalesCubit>().state;
        final sales = salesState is SalesLoaded
            ? salesState.sales
            : const <SaleModel>[];
        final collectionsState = context
            .watch<RepresentativeCollectionsCubit>()
            .state;
        final collections = collectionsState is RepresentativeCollectionsLoaded
            ? collectionsState.items
            : const <RepresentativeCollectionModel>[];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('Representatives'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: context.tr('Refresh'),
                    onPressed: () {
                      context.read<RepresentativesCubit>().load();
                      context.read<RepresentativeInventoryCubit>().load();
                      context.read<ProductsCubit>().load();
                      context.read<SalesCubit>().load();
                      context.read<RepresentativeCollectionsCubit>().load();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add representative')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is RepresentativesLoading)
                const LinearProgressIndicator()
              else
                const SizedBox(height: 4),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(context.tr('Name'))),
                          DataColumn(label: Text(context.tr('Phone'))),
                          DataColumn(
                            label: Text(context.tr('Items with rep')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(context.tr('Cost value')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(context.tr('Selling value')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(context.tr('Sales')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(context.tr('Collected')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(context.tr('Outstanding')),
                            numeric: true,
                          ),
                          DataColumn(label: Text(context.tr('Actions'))),
                        ],
                        rows: representatives
                            .map(
                              (item) => _row(
                                context,
                                item,
                                inventory,
                                products,
                                sales,
                                collections,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataRow _row(
    BuildContext context,
    RepresentativeModel representative,
    List<RepresentativeInventoryModel> inventory,
    Map<String, MedicineModel> products,
    List<SaleModel> sales,
    List<RepresentativeCollectionModel> collections,
  ) {
    final rows = inventory.where(
      (item) => item.representativeId == representative.id,
    );
    final quantity = rows.fold<int>(
      0,
      (sum, item) => sum + item.remainingQuantity,
    );
    final cost = rows.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.remainingQuantity *
              (products[item.productId]?.purchasePrice ?? 0),
    );
    final saleValue = rows.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.remainingQuantity *
              (products[item.productId]?.sellingPrice ?? 0),
    );
    final repSales = sales.where(
      (x) =>
          x.saleType == SaleType.representative &&
          x.representativeId == representative.id,
    );
    final totalSales = repSales.fold<double>(0, (sum, x) => sum + x.total);
    final totalCollected = collections
        .where((x) => x.representativeId == representative.id)
        .fold<double>(0, (sum, x) => sum + x.amount);
    return DataRow(
      cells: [
        DataCell(Text(representative.name)),
        DataCell(Text(representative.phone)),
        DataCell(Text('$quantity')),
        DataCell(Text(cost.toStringAsFixed(2))),
        DataCell(Text(saleValue.toStringAsFixed(2))),
        DataCell(Text(AppFormatters.currency.format(totalSales))),
        DataCell(Text(AppFormatters.currency.format(totalCollected))),
        DataCell(
          Text(AppFormatters.currency.format(totalSales - totalCollected)),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.tr('View details'),
                onPressed: () => _representativeDetails(
                  context,
                  representative,
                  repSales.toList(),
                  collections,
                ),
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: context.tr('Record collection'),
                onPressed: () => _collectionDialog(
                  context,
                  representative,
                  repSales.toList(),
                  collections,
                ),
                icon: const Icon(Icons.payments_outlined),
              ),
              IconButton(
                tooltip: context.tr('Edit'),
                onPressed: () => _openDialog(
                  context,
                  representative: representative,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: quantity > 0 || totalSales - totalCollected > 0.0001
                    ? context.tr(
                        'Settle representative account and return remaining stock before deleting',
                      )
                    : context.tr('Delete'),
                onPressed: quantity > 0 || totalSales - totalCollected > 0.0001
                    ? null
                    : () => _confirmDelete(context, representative),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDialog(
    BuildContext context, {
    RepresentativeModel? representative,
  }) async {
    final result = await showRepresentativeDialog(
      context,
      representative: representative,
    );
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<RepresentativesCubit>().createOrUpdate(
      id: representative?.id,
      name: result.name,
      phone: result.phone,
    );
  }

  Future<void> _collectionDialog(
    BuildContext context,
    RepresentativeModel representative,
    List<SaleModel> sales,
    List<RepresentativeCollectionModel> collections,
  ) async {
    final invoices = <String, _RepresentativeInvoice>{};
    for (final sale in sales) {
      final id = sale.invoiceId ?? sale.id;
      final old = invoices[id];
      invoices[id] = _RepresentativeInvoice(
        id: id,
        customerName: sale.customerName ?? context.tr('Customer'),
        total: (old?.total ?? 0) + sale.total,
        collected: old?.collected ?? 0,
      );
    }
    for (final collection in collections.where(
      (x) => x.representativeId == representative.id,
    )) {
      final invoice = invoices[collection.invoiceId];
      if (invoice != null)
        invoices[collection.invoiceId] = invoice.copyWith(
          collected: invoice.collected + collection.amount,
        );
    }
    final open = invoices.values.where((x) => x.outstanding > 0.0001).toList();
    if (open.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('No outstanding collections'))),
      );
      return;
    }
    var selected = open.first;
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${context.tr('Record collection')} — ${representative.name}',
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selected.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.tr('Invoice')),
                  items: open
                      .map(
                        (invoice) => DropdownMenuItem(
                          value: invoice.id,
                          child: Text(
                            '${invoice.customerName} · ${AppFormatters.currency.format(invoice.outstanding)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      selected = open.firstWhere((x) => x.id == value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Collection amount'),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    return parsed == null ||
                            parsed <= 0 ||
                            parsed > selected.outstanding
                        ? '${context.tr('Maximum')}: ${AppFormatters.currency.format(selected.outstanding)}'
                        : null;
                  },
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
      await context.read<RepresentativeCollectionsCubit>().collect(
        representativeId: representative.id,
        invoiceId: selected.id,
        amount: double.parse(amount.text),
      );
  }

  void _representativeDetails(
    BuildContext context,
    RepresentativeModel representative,
    List<SaleModel> sales,
    List<RepresentativeCollectionModel> collections,
  ) {
    final totals = <String, double>{};
    for (final sale in sales) {
      final id = sale.invoiceId ?? sale.id;
      totals[id] = (totals[id] ?? 0) + sale.total;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(representative.name),
        content: SizedBox(
          width: 600,
          height: 440,
          child: ListView(
            children: [
              Text(
                context.tr('Invoices'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...totals.entries.map((entry) {
                final paid = collections
                    .where(
                      (x) =>
                          x.representativeId == representative.id &&
                          x.invoiceId == entry.key,
                    )
                    .fold<double>(0, (sum, x) => sum + x.amount);
                return ListTile(
                  title: Text(AppFormatters.invoiceNumber(entry.key)),
                  subtitle: Text(
                    '${context.tr('Paid')}: ${AppFormatters.currency.format(paid)} · ${context.tr('Remaining')}: ${AppFormatters.currency.format(entry.value - paid)}',
                  ),
                  trailing: Text(AppFormatters.currency.format(entry.value)),
                );
              }),
              const Divider(),
              Text(
                context.tr('Payment history'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...collections
                  .where((x) => x.representativeId == representative.id)
                  .map(
                    (x) => ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(AppFormatters.currency.format(x.amount)),
                      subtitle: Text(
                        '${AppFormatters.invoiceNumber(x.invoiceId)} · ${AppFormatters.dateTime.format(x.date)}',
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RepresentativeModel representative,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete representative'),
        content: Text('Delete ${representative.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<RepresentativesCubit>().remove(representative.id);
    }
  }
}

class _RepresentativeInvoice {
  const _RepresentativeInvoice({
    required this.id,
    required this.customerName,
    required this.total,
    required this.collected,
  });
  final String id, customerName;
  final double total, collected;
  double get outstanding => total - collected;
  _RepresentativeInvoice copyWith({double? collected}) =>
      _RepresentativeInvoice(
        id: id,
        customerName: customerName,
        total: total,
        collected: collected ?? this.collected,
      );
}
