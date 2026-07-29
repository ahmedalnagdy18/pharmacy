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
import 'package:pharmacy/widgets/app_formatters.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _searchController = TextEditingController();
  String? _saleTypeFilter;

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
                                  onChanged: (_) => _applyFilter(),
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
                                  _applyFilter();
                                },
                              ),
                            ],
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
                                      DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Medicine')),
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
                                    ],
                                    rows: sales
                                        .map(
                                          (sale) => DataRow(
                                            cells: [
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

  void _applyFilter() {
    context.read<SalesCubit>().searchAndFilter(
      query: _searchController.text,
      saleType: _saleTypeFilter,
    );
  }

  Future<void> _openSaleDialog(
    BuildContext context, {
    required List<MedicineModel> products,
    required List<RepresentativeModel> representatives,
    required List<RepresentativeInventoryModel> inventory,
    required String saleType,
  }) async {
    final result = await showSaleDialog(
      context,
      products: products,
      representatives: representatives,
      inventory: inventory,
      saleType: saleType,
    );
    if (result == null || !context.mounted) {
      return;
    }
    final cubit = context.read<SalesCubit>();
    final productsCubit = context.read<ProductsCubit>();
    final inventoryCubit = context.read<RepresentativeInventoryCubit>();
    if (result.saleType == SaleType.direct) {
      await cubit.addDirectSale(
        productId: result.productId,
        quantity: result.quantity,
        unitPrice: result.unitPrice,
      );
    } else {
      await cubit.addRepresentativeSale(
        representativeId: result.representativeId!,
        productId: result.productId,
        quantity: result.quantity,
        unitPrice: result.unitPrice,
      );
    }
    await productsCubit.load();
    await inventoryCubit.load();
  }
}
