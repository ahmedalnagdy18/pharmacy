import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_cubit.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_state.dart';
import 'package:pharmacy/features/representative_inventory/presentation/widgets/assign_inventory_dialog.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';

class RepresentativeInventoryPage extends StatelessWidget {
  const RepresentativeInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      RepresentativeInventoryCubit,
      RepresentativeInventoryState
    >(
      builder: (context, inventoryState) {
        return BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, productsState) {
            return BlocBuilder<RepresentativesCubit, RepresentativesState>(
              builder: (context, representativesState) {
                final inventory =
                    inventoryState is RepresentativeInventoryLoaded
                    ? inventoryState.inventory
                    : const <RepresentativeInventoryModel>[];
                final products = productsState is ProductsLoaded
                    ? productsState.products
                    : const <MedicineModel>[];
                final representatives =
                    representativesState is RepresentativesLoaded
                    ? representativesState.representatives
                    : const <RepresentativeModel>[];
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
                            'Representative inventory',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            tooltip: 'Refresh',
                            onPressed: () {
                              context
                                  .read<RepresentativeInventoryCubit>()
                                  .load();
                              context.read<ProductsCubit>().load();
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed:
                                products.isEmpty || representatives.isEmpty
                                ? null
                                : () => _assign(
                                    context,
                                    products: products,
                                    representatives: representatives,
                                  ),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Assign'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (inventoryState is RepresentativeInventoryLoading)
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
                                  DataColumn(label: Text('Representative')),
                                  DataColumn(label: Text('Medicine')),
                                  DataColumn(
                                    label: Text('Assigned'),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Sold'),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Remaining'),
                                    numeric: true,
                                  ),
                                ],
                                rows: inventory
                                    .map(
                                      (item) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              representativeById[item
                                                          .representativeId]
                                                      ?.name ??
                                                  'Unknown',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              productById[item.productId]
                                                      ?.name ??
                                                  'Unknown',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              item.quantityAssigned.toString(),
                                            ),
                                          ),
                                          DataCell(
                                            Text(item.quantitySold.toString()),
                                          ),
                                          DataCell(
                                            Text(
                                              item.remainingQuantity.toString(),
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
  }

  Future<void> _assign(
    BuildContext context, {
    required List<RepresentativeModel> representatives,
    required List<MedicineModel> products,
  }) async {
    final result = await showAssignInventoryDialog(
      context,
      representatives: representatives,
      products: products,
    );
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<RepresentativeInventoryCubit>().assign(
      representativeId: result.representativeId,
      productId: result.productId,
      quantity: result.quantity,
    );
    if (context.mounted) {
      await context.read<ProductsCubit>().load();
    }
  }
}
