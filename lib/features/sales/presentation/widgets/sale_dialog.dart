import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';

class SaleFormResult {
  const SaleFormResult({
    required this.saleType,
    required this.lines,
    required this.amountPaid,
    this.customerName,
    this.customerPhone,
    this.representativeId,
  });
  final String saleType;
  final List<SaleLine> lines;
  final double amountPaid;
  final String? customerName, customerPhone, representativeId;
}

Future<SaleFormResult?> showSaleDialog(
  BuildContext context, {
  required List<MedicineModel> products,
  required List<RepresentativeModel> representatives,
  required List<RepresentativeInventoryModel> inventory,
  required String saleType,
  required List<CustomerModel> customers,
  required List<CustomerDebtModel> customerDebts,
}) => showDialog(
  context: context,
  builder: (_) => SaleDialog(
    products: products,
    representatives: representatives,
    inventory: inventory,
    initialSaleType: saleType,
    customers: customers,
    customerDebts: customerDebts,
  ),
);

class SaleDialog extends StatefulWidget {
  const SaleDialog({
    required this.products,
    required this.representatives,
    required this.inventory,
    required this.initialSaleType,
    required this.customers,
    required this.customerDebts,
    super.key,
  });
  final List<MedicineModel> products;
  final List<RepresentativeModel> representatives;
  final List<RepresentativeInventoryModel> inventory;
  final String initialSaleType;
  final List<CustomerModel> customers;
  final List<CustomerDebtModel> customerDebts;
  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleLineInput {
  _SaleLineInput({required this.productId, required String price})
    : quantity = TextEditingController(text: '1'),
      unitPrice = TextEditingController(text: price);
  String? productId;
  final TextEditingController quantity, unitPrice;
  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _SaleDialogState extends State<SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController(),
      _customerPhone = TextEditingController(),
      _paid = TextEditingController();
  late String _saleType;
  String? _representativeId;
  final List<_SaleLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _saleType = widget.initialSaleType;
    _representativeId = widget.representatives.firstOrNull?.id;
    _addLine();
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _paid.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  List<MedicineModel> get _availableProducts {
    if (_saleType == SaleType.direct) return widget.products;
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

  int _availableQuantity(String productId) => _saleType == SaleType.direct
      ? widget.products.firstWhere((p) => p.id == productId).quantity
      : widget.inventory
                .where(
                  (item) =>
                      item.representativeId == _representativeId &&
                      item.productId == productId,
                )
                .firstOrNull
                ?.remainingQuantity ??
            0;
  double get _total => _lines.fold(
    0,
    (sum, line) =>
        sum +
        (int.tryParse(line.quantity.text) ?? 0) *
            (double.tryParse(line.unitPrice.text) ?? 0),
  );
  void _addLine() {
    final product = _availableProducts.firstOrNull;
    if (product != null) {
      _lines.add(
        _SaleLineInput(
          productId: product.id,
          price: product.sellingPrice.toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _availableProducts;
    for (final line in _lines) {
      if (!products.any((p) => p.id == line.productId)) {
        line.productId = products.firstOrNull?.id;
      }
    }
    return AlertDialog(
      title: const Text('Create sale'),
      content: SizedBox(
        width: 650,
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
                  onSelectionChanged: (value) => setState(() {
                    _saleType = value.first;
                    _lines.clear();
                    _addLine();
                  }),
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
                          (x) => DropdownMenuItem(
                            value: x.id,
                            child: Text(x.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _representativeId = value;
                      _lines.clear();
                      _addLine();
                    }),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_saleType == SaleType.direct) ...[
                  Autocomplete<CustomerModel>(
                    displayStringForOption: (x) => '${x.name} (${x.phone})',
                    optionsBuilder: (value) => widget.customers.where(
                      (x) =>
                          value.text.isEmpty ||
                          x.name.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ) ||
                          x.phone.contains(value.text),
                    ),
                    onSelected: (x) => setState(() {
                      _customerName.text = x.name;
                      _customerPhone.text = x.phone;
                    }),
                    fieldViewBuilder: (_, controller, focusNode, _) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                          ),
                          onChanged: (value) {
                            _customerName.text = value;
                          },
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerPhone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Medicine')),
                    const Expanded(child: Text('Qty')),
                    const Expanded(child: Text('Unit price')),
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
                          child: DropdownButtonFormField<String>(
                            initialValue: line.productId,
                            items: products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      '${p.name} (${_availableQuantity(p.id)})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() {
                              line.productId = value;
                              final p = products.firstWhere(
                                (p) => p.id == value,
                              );
                              line.unitPrice.text = p.sellingPrice.toString();
                            }),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: line.quantity,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final quantity = int.tryParse(value ?? '');
                              return quantity == null ||
                                      quantity <= 0 ||
                                      (line.productId != null &&
                                          quantity >
                                              _availableQuantity(
                                                line.productId!,
                                              ))
                                  ? 'Invalid'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: line.unitPrice,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                double.tryParse(value ?? '') == null
                                ? 'Invalid'
                                : null,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Invoice total: ${_total.toStringAsFixed(2)} EGP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: products.isEmpty ? null : () => setState(_addLine),
                  icon: const Icon(Icons.add),
                  label: const Text('Add medicine'),
                ),
                if (_saleType == SaleType.direct)
                  TextFormField(
                    controller: _paid,
                    decoration: const InputDecoration(labelText: 'Amount paid'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      return amount == null || amount < 0 || amount > _total
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
        FilledButton(onPressed: _submit, child: const Text('Save sale')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SaleFormResult(
        saleType: _saleType,
        representativeId: _saleType == SaleType.representative
            ? _representativeId
            : null,
        lines: _lines
            .map(
              (x) => SaleLine(
                productId: x.productId!,
                quantity: int.parse(x.quantity.text),
                unitPrice: double.parse(x.unitPrice.text),
              ),
            )
            .toList(),
        amountPaid: _saleType == SaleType.direct ? double.parse(_paid.text) : 0,
        customerName: _saleType == SaleType.direct
            ? _customerName.text.trim()
            : null,
        customerPhone: _saleType == SaleType.direct
            ? _customerPhone.text.trim()
            : null,
      ),
    );
  }
}
