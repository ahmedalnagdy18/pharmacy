import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

class InventoryAssignmentResult {
  const InventoryAssignmentResult({
    required this.representativeId,
    required this.productId,
    required this.quantity,
  });

  final String representativeId;
  final String productId;
  final int quantity;
}

Future<InventoryAssignmentResult?> showAssignInventoryDialog(
  BuildContext context, {
  required List<RepresentativeModel> representatives,
  required List<MedicineModel> products,
}) {
  return showDialog<InventoryAssignmentResult>(
    context: context,
    builder: (_) => AssignInventoryDialog(
      representatives: representatives,
      products: products,
    ),
  );
}

class AssignInventoryDialog extends StatefulWidget {
  const AssignInventoryDialog({
    required this.representatives,
    required this.products,
    super.key,
  });

  final List<RepresentativeModel> representatives;
  final List<MedicineModel> products;

  @override
  State<AssignInventoryDialog> createState() => _AssignInventoryDialogState();
}

class _AssignInventoryDialogState extends State<AssignInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  String? _representativeId;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _representativeId = widget.representatives.firstOrNull?.id;
    _productId = widget.products.firstOrNull?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign inventory'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _representativeId,
                decoration: const InputDecoration(labelText: 'Representative'),
                items: widget.representatives
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _representativeId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: const InputDecoration(labelText: 'Medicine'),
                items: widget.products
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.quantity} in stock)'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _productId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  if (quantity == null || quantity <= 0) {
                    return 'Invalid quantity';
                  }
                  return null;
                },
              ),
            ],
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
          child: const Text('Assign'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      InventoryAssignmentResult(
        representativeId: _representativeId!,
        productId: _productId!,
        quantity: int.parse(_quantityController.text),
      ),
    );
  }
}
