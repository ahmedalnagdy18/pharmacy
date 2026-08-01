import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_cubit.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_state.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_state.dart';
import 'package:pharmacy/features/sales/presentation/widgets/sale_dialog.dart';
import 'package:pharmacy/features/sales/presentation/services/invoice_pdf_service.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_cubit.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_state.dart';
import 'package:pharmacy/widgets/date_filter_bar.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _searchController = TextEditingController();
  String? _saleTypeFilter;
  DateFilter _dateFilter = DateFilter.allTime;
  DateTime? _customDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, salesState) {
        return BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, productsState) {
            return BlocBuilder<RepresentativesCubit, RepresentativesState>(
              builder: (context, representativesState) {
                return BlocBuilder<
                  RepresentativeInventoryCubit,
                  RepresentativeInventoryState
                >(
                  builder: (context, inventoryState) {
                    final sales = salesState is SalesLoaded
                        ? salesState.sales
                        : const <SaleModel>[];
                    final products = productsState is ProductsLoaded
                        ? productsState.products
                        : const <MedicineModel>[];
                    final representatives =
                        representativesState is RepresentativesLoaded
                        ? representativesState.representatives
                        : const <RepresentativeModel>[];
                    final inventory =
                        inventoryState is RepresentativeInventoryLoaded
                        ? inventoryState.inventory
                        : const <RepresentativeInventoryModel>[];
                    final productById = {
                      for (final product in products) product.id: product,
                    };
                    final representativeById = {
                      for (final representative in representatives)
                        representative.id: representative,
                    };
                    final query = _searchController.text.trim().toLowerCase();
                    final filteredSales = sales
                        .where(
                          (sale) =>
                              (_saleTypeFilter == null ||
                                  sale.saleType == _saleTypeFilter) &&
                              matchesDateFilter(
                                sale.date,
                                _dateFilter,
                                _customDate,
                              ) &&
                              (query.isEmpty ||
                                  (productById[sale.productId]?.name
                                          .toLowerCase()
                                          .contains(query) ??
                                      false) ||
                                  (productById[sale.productId]?.barcode
                                          .toLowerCase()
                                          .contains(query) ??
                                      false)),
                        )
                        .toList();
                    final displaySales = _groupSales(
                      filteredSales,
                      productById,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Sales',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: 'Refresh',
                                onPressed: () {
                                  context.read<SalesCubit>().load();
                                  context.read<ProductsCubit>().load();
                                  context
                                      .read<RepresentativeInventoryCubit>()
                                      .load();
                                },
                                icon: const Icon(Icons.refresh),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: products.isEmpty
                                    ? null
                                    : () => _openSaleDialog(
                                        context,
                                        products: products,
                                        representatives: representatives,
                                        inventory: inventory,
                                        saleType: SaleType.direct,
                                      ),
                                icon: const Icon(Icons.point_of_sale_outlined),
                                label: const Text('New sale'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    labelText: 'Search by medicine or barcode',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SegmentedButton<String?>(
                                segments: const [
                                  ButtonSegment(
                                    value: null,
                                    label: Text('All'),
                                  ),
                                  ButtonSegment(
                                    value: SaleType.direct,
                                    label: Text('Direct'),
                                  ),
                                  ButtonSegment(
                                    value: SaleType.representative,
                                    label: Text('Representative'),
                                  ),
                                ],
                                selected: {_saleTypeFilter},
                                onSelectionChanged: (value) {
                                  setState(() => _saleTypeFilter = value.first);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DateFilterBar(
                            value: _dateFilter,
                            customDate: _customDate,
                            onChanged: (selection) => setState(() {
                              _dateFilter = selection.filter;
                              _customDate = selection.customDate;
                            }),
                          ),
                          const SizedBox(height: 12),
                          if (salesState is SalesLoading)
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
                                    columns: const [
                                      DataColumn(label: Text('Invoice')),
                                      DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Medicine')),
                                      DataColumn(label: Text('Customer')),
                                      DataColumn(label: Text('Phone')),
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Representative')),
                                      DataColumn(
                                        label: Text('Qty'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Unit'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Total'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Paid'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Remaining'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Invoice actions'),
                                      ),
                                    ],
                                    rows: displaySales
                                        .map(
                                          (sale) => DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  AppFormatters.invoiceNumber(
                                                    sale.invoiceId ?? sale.id,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  AppFormatters.dateTime.format(
                                                    sale.date,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  productById[sale.productId]
                                                          ?.name ??
                                                      'Unknown',
                                                ),
                                              ),
                                              DataCell(
                                                Text(sale.customerName ?? '-'),
                                              ),
                                              DataCell(
                                                Text(sale.customerPhone ?? '-'),
                                              ),
                                              DataCell(Text(sale.saleType)),
                                              DataCell(
                                                Text(
                                                  sale.representativeId == null
                                                      ? '-'
                                                      : representativeById[sale
                                                                    .representativeId]
                                                                ?.name ??
                                                            'Unknown',
                                                ),
                                              ),
                                              DataCell(
                                                Text(sale.quantity.toString()),
                                              ),
                                              DataCell(
                                                Text(
                                                  AppFormatters.currency.format(
                                                    sale.unitPrice,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  AppFormatters.currency.format(
                                                    sale.total,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  AppFormatters.currency.format(
                                                    sale.amountPaid ??
                                                        sale.total,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  AppFormatters.currency.format(
                                                    sale.total -
                                                        (sale.amountPaid ??
                                                            sale.total),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Print invoice',
                                                      icon: const Icon(
                                                        Icons.print_outlined,
                                                      ),
                                                      onPressed: () => InvoicePdfService.print(
                                                        sales
                                                            .where(
                                                              (item) =>
                                                                  (item.invoiceId ??
                                                                      item.id) ==
                                                                  (sale.invoiceId ??
                                                                      sale.id),
                                                            )
                                                            .toList(),
                                                        productById,
                                                        sale.representativeId ==
                                                                null
                                                            ? null
                                                            : representativeById[sale
                                                                  .representativeId],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Export PDF',
                                                      icon: const Icon(
                                                        Icons
                                                            .picture_as_pdf_outlined,
                                                      ),
                                                      onPressed: () => InvoicePdfService.share(
                                                        sales
                                                            .where(
                                                              (item) =>
                                                                  (item.invoiceId ??
                                                                      item.id) ==
                                                                  (sale.invoiceId ??
                                                                      sale.id),
                                                            )
                                                            .toList(),
                                                        productById,
                                                        sale.representativeId ==
                                                                null
                                                            ? null
                                                            : representativeById[sale
                                                                  .representativeId],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Cancel invoice',
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                      onPressed: () =>
                                                          _confirmCancelInvoice(
                                                            context,
                                                            sale.invoiceId ??
                                                                sale.id,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
              },
            );
          },
        );
      },
    );
  }

  List<SaleModel> _groupSales(
    List<SaleModel> sales,
    Map<String, MedicineModel> products,
  ) {
    final groups = <String, List<SaleModel>>{};
    for (final sale in sales) {
      groups.putIfAbsent(sale.invoiceId ?? sale.id, () => []).add(sale);
    }
    return groups.entries.map((entry) {
      final items = entry.value;
      final first = items.first;
      final total = items.fold<double>(0, (sum, item) => sum + item.total);
      final paid = first.amountPaid ?? total;
      final names = items
          .map(
            (item) =>
                '${products[item.productId]?.name ?? 'Unknown'} ×${item.quantity}',
          )
          .join(', ');
      final baseProduct = products[first.productId];
      if (baseProduct != null) {
        products[entry.key] = baseProduct.copyWith(id: entry.key, name: names);
      }
      return first.copyWith(
        productId: entry.key,
        quantity: items.fold<int>(0, (sum, item) => sum + item.quantity),
        unitPrice:
            total / items.fold<int>(0, (sum, item) => sum + item.quantity),
        total: total,
        amountPaid: paid,
      );
    }).toList();
  }

  Future<void> _confirmCancelInvoice(
    BuildContext context,
    String invoiceId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel invoice'),
        content: const Text(
          'This will remove the complete invoice, restore stock, and remove its unpaid debt. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep invoice'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel invoice'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SalesCubit>().cancelInvoice(invoiceId);
      if (!context.mounted) return;
      await context.read<ProductsCubit>().load();
      if (!context.mounted) return;
      await context.read<RepresentativeInventoryCubit>().load();
      if (!context.mounted) return;
      await context.read<CustomersCubit>().load();
    }
  }

  Future<void> _openSaleDialog(
    BuildContext context, {
    required List<MedicineModel> products,
    required List<RepresentativeModel> representatives,
    required List<RepresentativeInventoryModel> inventory,
    required String saleType,
  }) async {
    final customerState = context.read<CustomersCubit>().state;
    final customers = customerState is CustomersLoaded
        ? customerState.customers
        : const <CustomerModel>[];
    final customerDebts = customerState is CustomersLoaded
        ? customerState.debts
        : const <CustomerDebtModel>[];
    final result = await showSaleDialog(
      context,
      products: products,
      representatives: representatives,
      inventory: inventory,
      saleType: saleType,
      customers: customers,
      customerDebts: customerDebts,
    );
    if (result == null || !context.mounted) {
      return;
    }
    final cubit = context.read<SalesCubit>();
    final productsCubit = context.read<ProductsCubit>();
    final inventoryCubit = context.read<RepresentativeInventoryCubit>();
    if (result.saleType == SaleType.direct) {
      await cubit.addDirectSales(
        lines: result.lines,
        amountPaid: result.amountPaid,
        customerName: result.customerName,
        customerPhone: result.customerPhone,
      );
    } else {
      await cubit.addRepresentativeSales(
        representativeId: result.representativeId!,
        lines: result.lines,
      );
    }
    await productsCubit.load();
    await inventoryCubit.load();
  }
}
