import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/products/presentation/widgets/product_dialog.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final allProducts = state is ProductsLoaded
            ? state.products
            : const <MedicineModel>[];
        final query = _searchController.text.trim().toLowerCase();
        final products = allProducts
            .where(
              (product) =>
                  query.isEmpty ||
                  product.name.toLowerCase().contains(query) ||
                  product.barcode.toLowerCase().contains(query) ||
                  product.category.toLowerCase().contains(query),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Products',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () => context.read<ProductsCubit>().load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add medicine'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search by medicine, barcode, or category',
                ),
              ),
              const SizedBox(height: 12),
              if (state is ProductsLoading)
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
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Barcode')),
                          DataColumn(label: Text('Qty'), numeric: true),
                          DataColumn(label: Text('Purchase'), numeric: true),
                          DataColumn(label: Text('Selling'), numeric: true),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: products
                            .map((product) => _row(context, product))
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

  DataRow _row(BuildContext context, MedicineModel product) {
    return DataRow(
      cells: [
        DataCell(Text(product.name)),
        DataCell(Text(product.category)),
        DataCell(Text(product.barcode)),
        DataCell(Text(product.quantity.toString())),
        DataCell(Text(AppFormatters.currency.format(product.purchasePrice))),
        DataCell(Text(AppFormatters.currency.format(product.sellingPrice))),
        DataCell(Text(AppFormatters.date.format(product.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openDialog(context, product: product),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, product),
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
    MedicineModel? product,
  }) async {
    final result = await showProductDialog(context, product: product);
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<ProductsCubit>().createOrUpdate(
      id: product?.id,
      name: result.name,
      category: result.category,
      barcode: result.barcode,
      quantity: result.quantity,
      purchasePrice: result.purchasePrice,
      sellingPrice: result.sellingPrice,
      notes: result.notes,
      createdAt: product?.createdAt,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MedicineModel product,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete medicine'),
        content: Text('Delete ${product.name}?'),
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
      await context.read<ProductsCubit>().remove(product.id);
    }
  }
}
