import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';

class ProductFormResult {
  const ProductFormResult({
    required this.name,
    required this.category,
    required this.barcode,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.notes,
  });

  final String name;
  final String category;
  final String barcode;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final String notes;
}

Future<ProductFormResult?> showProductDialog(
  BuildContext context, {
  MedicineModel? product,
}) {
  return showDialog<ProductFormResult>(
    context: context,
    builder: (_) => ProductDialog(product: product),
  );
}

class ProductDialog extends StatefulWidget {
  const ProductDialog({this.product, super.key});

  final MedicineModel? product;

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '0',
    );
    _purchasePriceController = TextEditingController(
      text: product?.purchasePrice.toString() ?? '0',
    );
    _sellingPriceController = TextEditingController(
      text: product?.sellingPrice.toString() ?? '0',
    );
    _notesController = TextEditingController(text: product?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add medicine' : 'Edit medicine'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        controller: _quantityController,
                        label: 'Quantity',
                        integerOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        controller: _purchasePriceController,
                        label: 'Purchase price',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        controller: _sellingPriceController,
                        label: 'Selling price',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  TextFormField _numberField({
    required TextEditingController controller,
    required String label,
    bool integerOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          integerOnly ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      validator: (value) {
        final text = value?.trim() ?? '';
        final number = integerOnly ? int.tryParse(text) : double.tryParse(text);
        if (number == null || number < 0) {
          return 'Invalid';
        }
        return null;
      },
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      ProductFormResult(
        name: _nameController.text,
        category: _categoryController.text,
        barcode: _barcodeController.text,
        quantity: int.parse(_quantityController.text),
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        notes: _notesController.text,
      ),
    );
  }
}
