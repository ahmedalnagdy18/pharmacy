import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_cubit.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_state.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_cubit.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/widgets/date_filter_bar.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  DateFilter _dateFilter = DateFilter.allTime;
  DateTime? _customDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchasesCubit, PurchasesState>(
      builder: (context, purchaseState) =>
          BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, productState) =>
                BlocBuilder<SuppliersCubit, SuppliersState>(
                  builder: (context, supplierState) {
                    final products = productState is ProductsLoaded
                        ? productState.products
                        : const <MedicineModel>[];
                    final suppliers = supplierState is SuppliersLoaded
                        ? supplierState.suppliers
                        : const <SupplierModel>[];
                    final purchases = purchaseState is PurchasesLoaded
                        ? purchaseState.purchases
                        : const <PurchaseModel>[];
                    final filteredPurchases = purchases
                        .where(
                          (purchase) => matchesDateFilter(
                            purchase.date,
                            _dateFilter,
                            _customDate,
                          ),
                        )
                        .toList();
                    final productById = {for (final p in products) p.id: p};
                    final supplierById = {for (final s in suppliers) s.id: s};
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.tr('Purchases'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: 'Refresh',
                                onPressed: () =>
                                    context.read<PurchasesCubit>().load(),
                                icon: const Icon(Icons.refresh),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: products.isEmpty || suppliers.isEmpty
                                    ? null
                                    : () =>
                                          _dialog(context, products, suppliers),
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                ),
                                label: Text(context.tr('New purchase')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DateFilterBar(
                            value: _dateFilter,
                            customDate: _customDate,
                            onChanged: (selection) => setState(() {
                              _dateFilter = selection.filter;
                              _customDate = selection.customDate;
                            }),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text(context.tr('Date'))),
                                    DataColumn(
                                      label: Text(context.tr('Suppliers')),
                                    ),
                                    DataColumn(
                                      label: Text(context.tr('Medicine')),
                                    ),
                                    DataColumn(label: Text(context.tr('Qty'))),
                                    DataColumn(
                                      label: Text(context.tr('Total')),
                                    ),
                                    DataColumn(label: Text(context.tr('Paid'))),
                                    DataColumn(
                                      label: Text(context.tr('Remaining')),
                                    ),
                                  ],
                                  rows: _purchaseRows(
                                    filteredPurchases,
                                    productById,
                                    supplierById,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }

  List<DataRow> _purchaseRows(
    List<PurchaseModel> purchases,
    Map<String, MedicineModel> products,
    Map<String, SupplierModel> suppliers,
  ) {
    final groups = <String, List<PurchaseModel>>{};
    for (final purchase in purchases) {
      groups
          .putIfAbsent(purchase.invoiceId ?? purchase.id, () => [])
          .add(purchase);
    }
    return groups.values.map((items) {
      final first = items.first;
      final total = items.fold<double>(0, (sum, item) => sum + item.total);
      final paid = items.fold<double>(0, (sum, item) => sum + item.paidAmount);
      final medicineNames = items
          .map(
            (item) =>
                '${products[item.productId]?.name ?? 'Unknown'} ×${item.quantity}',
          )
          .join('\n');
      return DataRow(
        cells: [
          DataCell(Text(AppFormatters.date.format(first.date))),
          DataCell(Text(suppliers[first.supplierId]?.name ?? 'Unknown')),
          DataCell(Text(medicineNames)),
          DataCell(
            Text(
              items.fold<int>(0, (sum, item) => sum + item.quantity).toString(),
            ),
          ),
          DataCell(Text(AppFormatters.currency.format(total))),
          DataCell(Text(AppFormatters.currency.format(paid))),
          DataCell(Text(AppFormatters.currency.format(total - paid))),
        ],
      );
    }).toList();
  }

  Future<void> _dialog(
    BuildContext context,
    List<MedicineModel> products,
    List<SupplierModel> suppliers,
  ) async {
    final result = await showDialog<_PurchaseFormResult>(
      context: context,
      builder: (_) => _PurchaseDialog(products: products, suppliers: suppliers),
    );
    if (result != null && context.mounted) {
      await context.read<PurchasesCubit>().create(
        supplierId: result.supplierId,
        lines: result.lines,
        paidAmount: result.paidAmount,
      );
      if (!context.mounted) {
        return;
      }
      await context.read<ProductsCubit>().load();
      if (!context.mounted) {
        return;
      }
      await context.read<SuppliersCubit>().load();
    }
  }
}

class _PurchaseFormResult {
  const _PurchaseFormResult({
    required this.supplierId,
    required this.lines,
    required this.paidAmount,
  });
  final String supplierId;
  final List<PurchaseLine> lines;
  final double paidAmount;
}

class _PurchaseLineInput {
  _PurchaseLineInput(MedicineModel product)
    : productId = product.id,
      quantity = TextEditingController(text: '1'),
      cost = TextEditingController(text: product.purchasePrice.toString());
  String productId;
  final TextEditingController quantity, cost;
  void dispose() {
    quantity.dispose();
    cost.dispose();
  }
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog({required this.products, required this.suppliers});
  final List<MedicineModel> products;
  final List<SupplierModel> suppliers;
  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  final _form = GlobalKey<FormState>();
  late String _supplierId;
  final _paid = TextEditingController(text: '0');
  final List<_PurchaseLineInput> _lines = [];
  @override
  void initState() {
    super.initState();
    _supplierId = widget.suppliers.first.id;
    _lines.add(_PurchaseLineInput(widget.products.first));
  }

  @override
  void dispose() {
    _paid.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _total => _lines.fold(
    0,
    (sum, line) =>
        sum +
        (int.tryParse(line.quantity.text) ?? 0) *
            (double.tryParse(line.cost.text) ?? 0),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New purchase'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _supplierId,
                items: widget.suppliers
                    .map(
                      (x) => DropdownMenuItem(value: x.id, child: Text(x.name)),
                    )
                    .toList(),
                onChanged: (x) => _supplierId = x!,
                decoration: const InputDecoration(labelText: 'Supplier'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('Medicine')),
                  const Expanded(child: Text('Qty')),
                  const Expanded(child: Text('Unit cost')),
                  const SizedBox(width: 40),
                ],
              ),
              ..._lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Autocomplete<MedicineModel>(
                          displayStringForOption: (x) => x.name,
                          optionsBuilder: (value) => widget.products.where(
                            (x) => x.name.toLowerCase().contains(
                              value.text.toLowerCase(),
                            ),
                          ),
                          onSelected: (x) => setState(() {
                            line.productId = x.id;
                            line.cost.text = x.purchasePrice.toString();
                          }),
                          fieldViewBuilder: (_, controller, focusNode, _) {
                            final product = widget.products.firstWhere(
                              (x) => x.id == line.productId,
                            );
                            if (controller.text.isEmpty)
                              controller.text = product.name;
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Search medicine',
                              ),
                              validator: (_) =>
                                  line.productId.isEmpty ? 'Required' : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: line.quantity,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          validator: (x) => (int.tryParse(x ?? '') ?? 0) > 0
                              ? null
                              : 'Invalid',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: line.cost,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          validator: (x) =>
                              (double.tryParse(x ?? '') ?? -1) >= 0
                              ? null
                              : 'Invalid',
                        ),
                      ),
                      IconButton(
                        onPressed: _lines.length == 1
                            ? null
                            : () => setState(() {
                                final removed = _lines.removeAt(index);
                                removed.dispose();
                              }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(
                  () => _lines.add(_PurchaseLineInput(widget.products.first)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add medicine'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Invoice total: ${_total.toStringAsFixed(2)} EGP',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _paid,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount paid'),
                validator: (x) {
                  final value = double.tryParse(x ?? '');
                  return value == null || value < 0 || value > _total
                      ? 'Enter an amount up to ${_total.toStringAsFixed(2)}'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate())
            Navigator.pop(
              context,
              _PurchaseFormResult(
                supplierId: _supplierId,
                paidAmount: double.parse(_paid.text),
                lines: _lines
                    .map(
                      (x) => PurchaseLine(
                        productId: x.productId,
                        quantity: int.parse(x.quantity.text),
                        unitCost: double.parse(x.cost.text),
                      ),
                    )
                    .toList(),
              ),
            );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
