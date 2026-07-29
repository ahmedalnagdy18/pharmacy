import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';

class SaleFormResult {
  const SaleFormResult({
    required this.saleType,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.representativeId,
  });

  final String saleType;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? representativeId;
}

Future<SaleFormResult?> showSaleDialog(
  BuildContext context, {
  required List<MedicineModel> products,
  required List<RepresentativeModel> representatives,
  required List<RepresentativeInventoryModel> inventory,
  required String saleType,
}) {
  return showDialog<SaleFormResult>(
    context: context,
    builder: (_) => SaleDialog(
      products: products,
      representatives: representatives,
      inventory: inventory,
      initialSaleType: saleType,
    ),
  );
}

class SaleDialog extends StatefulWidget {
  const SaleDialog({
    required this.products,
    required this.representatives,
    required this.inventory,
    required this.initialSaleType,
    super.key,
  });

  final List<MedicineModel> products;
  final List<RepresentativeModel> representatives;
  final List<RepresentativeInventoryModel> inventory;
  final String initialSaleType;

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController(text: '0');
  late String _saleType;
  String? _representativeId;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _saleType = widget.initialSaleType;
    _representativeId = widget.representatives.firstOrNull?.id;
    _productId = _availableProducts.firstOrNull?.id;
    _syncPrice();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  List<MedicineModel> get _availableProducts {
    if (_saleType == SaleType.direct) {
      return widget.products;
    }
    final ids = widget.inventory
        .where(
          (item) =>
              item.representativeId == _representativeId &&
              item.remainingQuantity > 0,
        )
        .map((item) => item.productId)
        .toSet();
    return widget.products
        .where((product) => ids.contains(product.id))
        .toList();
  }

  int _availableQuantity(String productId) {
    if (_saleType == SaleType.direct) {
      return widget.products
              .where((product) => product.id == productId)
              .firstOrNull
              ?.quantity ??
          0;
    }
    final item = widget.inventory
        .where(
          (inventory) =>
              inventory.representativeId == _representativeId &&
              inventory.productId == productId,
        )
        .firstOrNull;
    return item?.remainingQuantity ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final availableProducts = _availableProducts;
    if (_productId != null &&
        !availableProducts.any((product) => product.id == _productId)) {
      _productId = availableProducts.firstOrNull?.id;
      _syncPrice();
    }

    return AlertDialog(
      title: const Text('Create sale'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: SaleType.direct,
                      icon: Icon(Icons.storefront_outlined),
                      label: Text('Direct'),
                    ),
                    ButtonSegment(
                      value: SaleType.representative,
                      icon: Icon(Icons.badge_outlined),
                      label: Text('Representative'),
                    ),
                  ],
                  selected: {_saleType},
                  onSelectionChanged: (value) {
                    setState(() {
                      _saleType = value.first;
                      _productId = _availableProducts.firstOrNull?.id;
                      _syncPrice();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_saleType == SaleType.representative) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _representativeId,
                    decoration: const InputDecoration(
                      labelText: 'Representative',
                    ),
                    items: widget.representatives
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _representativeId = value;
                        _productId = _availableProducts.firstOrNull?.id;
                        _syncPrice();
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _productId,
                  decoration: const InputDecoration(labelText: 'Medicine'),
                  items: availableProducts
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (${_availableQuantity(item.id)} available)',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _productId = value;
                      _syncPrice();
                    });
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '');
                          if (quantity == null || quantity <= 0) {
                            return 'Invalid';
                          }
                          if (_productId != null &&
                              quantity > _availableQuantity(_productId!)) {
                            return 'Too high';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit price',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (value) {
                          final price = double.tryParse(value ?? '');
                          if (price == null || price < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
          child: const Text('Save sale'),
        ),
      ],
    );
  }

  void _syncPrice() {
    final product = widget.products
        .where((product) => product.id == _productId)
        .firstOrNull;
    if (product != null) {
      _unitPriceController.text = product.sellingPrice.toString();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      SaleFormResult(
        saleType: _saleType,
        representativeId: _saleType == SaleType.representative
            ? _representativeId
            : null,
        productId: _productId!,
        quantity: int.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
      ),
    );
  }
}
