import 'package:flutter/material.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';

class ProductSearchField extends StatefulWidget {
  const ProductSearchField({
    required this.products,
    required this.selectedProductId,
    required this.availableQuantity,
    required this.label,
    required this.onSelected,
    super.key,
  });

  final List<MedicineModel> products;
  final String? selectedProductId;
  final int Function(String productId) availableQuantity;
  final String label;
  final ValueChanged<MedicineModel> onSelected;

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedName);
  }

  String get _selectedName =>
      widget.products
          .where((product) => product.id == widget.selectedProductId)
          .map((product) => product.name)
          .firstOrNull ??
      '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<MedicineModel>(
      displayStringForOption: (product) => product.name,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        return widget.products.where(
          (product) =>
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.barcode.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query),
        );
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (_, controller, focusNode, _) {
        if (controller.text.isEmpty && _controller.text.isNotEmpty) {
          controller.text = _controller.text;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        );
      },
      optionsViewBuilder: (_, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, index) {
                final product = options.elementAt(index);
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('${product.barcode} • ${product.category}'),
                  trailing: Text('${widget.availableQuantity(product.id)}'),
                  onTap: () => onSelected(product),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
