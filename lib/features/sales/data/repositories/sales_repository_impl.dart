import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/repositories/sales_repository.dart';
import 'package:pharmacy/features/customers/data/data_source/customers_local_data_source.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:uuid/uuid.dart';
import 'package:pharmacy/features/representatives/data/data_source/representative_collections_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl({
    required this.salesDataSource,
    required this.productsDataSource,
    required this.inventoryDataSource,
    required this.customersDataSource,
    required this.representativeCollectionsDataSource,
  });

  final SalesLocalDataSource salesDataSource;
  final ProductsLocalDataSource productsDataSource;
  final RepresentativeInventoryLocalDataSource inventoryDataSource;
  final CustomersLocalDataSource customersDataSource;
  final RepresentativeCollectionsLocalDataSource
  representativeCollectionsDataSource;

  @override
  Future<List<SaleModel>> getSales() => salesDataSource.getAll();

  @override
  Future<List<SaleModel>> getTodaySales() async {
    final now = DateTime.now();
    return (await getSales()).where((sale) {
      return sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day;
    }).toList();
  }

  @override
  Future<List<SaleModel>> getMonthlySales(DateTime month) async {
    return (await getSales()).where((sale) {
      return sale.date.year == month.year && sale.date.month == month.month;
    }).toList();
  }

  @override
  Future<List<SaleModel>> searchSales(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return getSales();
    }
    final products = await productsDataSource.getAll();
    final matchingProductIds = products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalizedQuery) ||
              product.barcode.toLowerCase().contains(normalizedQuery),
        )
        .map((product) => product.id)
        .toSet();
    return (await getSales())
        .where((sale) => matchingProductIds.contains(sale.productId))
        .toList();
  }

  @override
  Future<List<SaleModel>> filterSales(String? saleType) async {
    if (saleType == null || saleType.isEmpty) {
      return getSales();
    }
    return (await getSales())
        .where((sale) => sale.saleType == saleType)
        .toList();
  }

  @override
  Future<void> createDirectSales(List<SaleModel> sales) async {
    if (sales.isEmpty) throw const AppException('Add at least one medicine.');
    _validateLines(sales);
    final firstSale = sales.first;
    final invoiceTotal = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    if (!invoiceTotal.isFinite) {
      throw const AppException('Invoice total is invalid.');
    }
    final paid = firstSale.amountPaid ?? invoiceTotal;
    if (!paid.isFinite || paid < 0 || paid > invoiceTotal) {
      throw const AppException(
        'Paid amount must be between zero and the invoice total.',
      );
    }
    // Validate stock before creating a customer, so a failed sale never leaves
    // an orphan customer record behind.
    final requested = _quantitiesByProduct(sales);
    for (final entry in requested.entries) {
      final product = await productsDataSource.getById(entry.key);
      if (product == null) throw const AppException('Product was not found.');
      if (product.quantity < entry.value) {
        throw const AppException('Not enough warehouse stock.');
      }
    }
    String? customerId = firstSale.customerId;
    if (customerId != null &&
        await customersDataSource.getCustomer(customerId) == null) {
      throw const AppException('Customer was not found.');
    }
    if ((firstSale.customerName ?? '').trim().isNotEmpty ||
        (firstSale.customerPhone ?? '').trim().isNotEmpty) {
      final name = (firstSale.customerName ?? '').trim();
      final phone = (firstSale.customerPhone ?? '').trim();
      if (name.isEmpty || phone.isEmpty) {
        throw const AppException(
          'Customer name and phone are required for a direct sale.',
        );
      }
      final existing = await customersDataSource.findByPhone(phone);
      if (existing != null) {
        customerId = existing.id;
      } else {
        customerId ??= const Uuid().v4();
        await customersDataSource.saveCustomer(
          CustomerModel(
            id: customerId,
            name: name,
            phone: phone,
            address: '',
            notes: '',
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    if (paid < invoiceTotal && customerId == null) {
      throw const AppException('A customer is required for a partial payment.');
    }
    var remainingPaid = paid;
    for (final sale in sales) {
      final product = await productsDataSource.getById(sale.productId);
      await productsDataSource.save(
        product!.copyWith(quantity: product.quantity - sale.quantity),
      );
      final linePaid = remainingPaid.clamp(0, sale.total).toDouble();
      remainingPaid -= linePaid;
      await salesDataSource.save(
        sale.copyWith(
          saleType: SaleType.direct,
          customerId: customerId,
          invoiceId: firstSale.invoiceId ?? firstSale.id,
          amountPaid: linePaid,
          unitCost: product.purchasePrice,
        ),
      );
    }
    final remaining = invoiceTotal - paid;
    if (remaining > 0) {
      final now = DateTime.now();
      await customersDataSource.saveDebt(
        CustomerDebtModel(
          id: const Uuid().v4(),
          customerId: customerId!,
          invoiceId: firstSale.invoiceId ?? firstSale.id,
          invoiceTotal: invoiceTotal,
          paidAmount: paid,
          remainingAmount: remaining,
          status: DebtStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Future<void> createRepresentativeSales(List<SaleModel> sales) async {
    if (sales.isEmpty) throw const AppException('Add at least one medicine.');
    _validateLines(sales);
    final representativeId = sales.first.representativeId;
    if (representativeId == null || representativeId.isEmpty) {
      throw const AppException('Representative is required.');
    }
    String? customerId;
    final customerName = (sales.first.customerName ?? '').trim();
    final customerPhone = (sales.first.customerPhone ?? '').trim();
    if (customerName.isEmpty || customerPhone.isEmpty) {
      throw const AppException(
        'Customer name and phone are required for a representative sale.',
      );
    }
    for (final sale in sales) {
      if (sale.representativeId != representativeId) {
        throw const AppException('Check sale items and representative.');
      }
      if (await productsDataSource.getById(sale.productId) == null) {
        throw const AppException('Product was not found.');
      }
    }
    final requested = _quantitiesByProduct(sales);
    for (final entry in requested.entries) {
      final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
        representativeId: representativeId,
        productId: entry.key,
      );
      if (inventory == null || inventory.remainingQuantity < entry.value) {
        throw const AppException('Not enough representative stock.');
      }
    }
    final existingCustomer = await customersDataSource.findByPhone(
      customerPhone,
    );
    if (existingCustomer != null) {
      customerId = existingCustomer.id;
    } else {
      customerId = const Uuid().v4();
      await customersDataSource.saveCustomer(
        CustomerModel(
          id: customerId,
          name: customerName,
          phone: customerPhone,
          address: '',
          notes: '',
          createdAt: DateTime.now(),
        ),
      );
    }
    for (final sale in sales) {
      final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
        representativeId: representativeId,
        productId: sale.productId,
      );
      await inventoryDataSource.save(
        inventory!.copyWith(
          quantitySold: inventory.quantitySold + sale.quantity,
        ),
      );
      await salesDataSource.save(
        sale.copyWith(
          saleType: SaleType.representative,
          invoiceId: sales.first.invoiceId ?? sales.first.id,
          customerId: customerId,
          amountPaid: 0,
          unitCost:
              (await productsDataSource.getById(
                sale.productId,
              ))?.purchasePrice ??
              0,
        ),
      );
    }
  }

  @override
  Future<void> recordRepresentativeCollection({
    required String id,
    required String representativeId,
    required String invoiceId,
    required double amount,
    String notes = '',
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw const AppException('Collection amount is invalid.');
    }
    final invoiceSales = (await salesDataSource.getAll())
        .where((sale) => (sale.invoiceId ?? sale.id) == invoiceId)
        .toList();
    if (invoiceSales.isEmpty ||
        invoiceSales.any(
          (sale) =>
              sale.saleType != SaleType.representative ||
              sale.representativeId != representativeId,
        )) {
      throw const AppException('Representative invoice was not found.');
    }
    final invoiceTotal = invoiceSales.fold<double>(
      0,
      (sum, sale) => sum + sale.total,
    );
    final alreadyCollected =
        (await representativeCollectionsDataSource.getAll())
            .where((item) => item.invoiceId == invoiceId)
            .fold<double>(0, (sum, item) => sum + item.amount);
    if (amount - (invoiceTotal - alreadyCollected) > 0.000001) {
      throw const AppException(
        'Collection cannot exceed the invoice outstanding balance.',
      );
    }
    await representativeCollectionsDataSource.save(
      RepresentativeCollectionModel(
        id: id,
        representativeId: representativeId,
        invoiceId: invoiceId,
        amount: amount,
        date: DateTime.now(),
        notes: notes.trim(),
      ),
    );
  }

  @override
  Future<void> updateInvoice(
    String invoiceId,
    List<SaleModel> sales, {
    required double amountPaid,
  }) async {
    if (sales.isEmpty) throw const AppException('Add at least one medicine.');
    _validateLines(sales);

    final allSales = await salesDataSource.getAll();
    final oldSales = allSales
        .where(
          (sale) => sale.invoiceId == invoiceId || sale.id == invoiceId,
        )
        .toList();
    if (oldSales.isEmpty) throw const AppException('Invoice was not found.');

    final canonicalInvoiceId = oldSales.first.invoiceId ?? oldSales.first.id;
    final saleType = oldSales.first.saleType;
    if (oldSales.any((sale) => sale.saleType != saleType) ||
        sales.any((sale) => sale.saleType != saleType)) {
      throw const AppException('Invoice type cannot be changed.');
    }

    final invoiceTotal = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.total,
    );
    if (!invoiceTotal.isFinite) {
      throw const AppException('Invoice total is invalid.');
    }
    final oldQuantities = _quantitiesByProduct(oldSales);
    final newQuantities = _quantitiesByProduct(sales);
    final originalCosts = <String, double>{
      for (final sale in oldSales) sale.productId: sale.unitCost,
    };

    String? customerId = oldSales.first.customerId;
    if (saleType == SaleType.direct) {
      if (!amountPaid.isFinite || amountPaid < 0 || amountPaid > invoiceTotal) {
        throw const AppException(
          'Paid amount must be between zero and the invoice total.',
        );
      }
      final debts = (await customersDataSource.getDebts())
          .where((debt) => debt.invoiceId == canonicalInvoiceId)
          .toList();
      final payments = await customersDataSource.getPayments();
      if (debts.any(
        (debt) => payments.any((payment) => payment.debtId == debt.id),
      )) {
        throw const AppException(
          'Invoices with recorded debt payments cannot be edited.',
        );
      }
      customerId = await _resolveCustomer(sales.first, customerId);
      if (amountPaid < invoiceTotal && customerId == null) {
        throw const AppException(
          'A customer is required for a partial payment.',
        );
      }
      await _applyWarehouseQuantityChanges(oldQuantities, newQuantities);
      await _replaceInvoiceLines(
        oldSales: oldSales,
        newSales: sales,
        canonicalInvoiceId: canonicalInvoiceId,
        customerId: customerId,
        amountPaid: amountPaid,
        originalCosts: originalCosts,
      );
      await _syncCustomerDebt(
        invoiceId: canonicalInvoiceId,
        customerId: customerId,
        invoiceTotal: invoiceTotal,
        amountPaid: amountPaid,
        invoiceDate: oldSales.first.date,
      );
      return;
    }

    final representativeId = oldSales.first.representativeId;
    if (representativeId == null ||
        sales.any((sale) => sale.representativeId != representativeId)) {
      throw const AppException('Invoice representative cannot be changed.');
    }
    final collected = (await representativeCollectionsDataSource.getAll())
        .where((item) => item.invoiceId == canonicalInvoiceId)
        .fold<double>(0, (sum, item) => sum + item.amount);
    if (collected - invoiceTotal > 0.000001) {
      throw const AppException(
        'Invoice total cannot be lower than its recorded collections.',
      );
    }
    customerId = await _resolveCustomer(sales.first, customerId);
    if (customerId == null) {
      throw const AppException(
        'Customer name and phone are required for a representative sale.',
      );
    }
    await _applyRepresentativeQuantityChanges(
      representativeId,
      oldQuantities,
      newQuantities,
    );
    await _replaceInvoiceLines(
      oldSales: oldSales,
      newSales: sales,
      canonicalInvoiceId: canonicalInvoiceId,
      customerId: customerId,
      amountPaid: 0,
      originalCosts: originalCosts,
    );
  }

  void _validateLines(List<SaleModel> sales) {
    final ids = <String>{};
    final invoiceId = sales.first.invoiceId;
    for (final sale in sales) {
      final expectedTotal = sale.quantity * sale.unitPrice;
      if (!ids.add(sale.id)) {
        throw const AppException('Sale line identifiers must be unique.');
      }
      if (sale.quantity <= 0 ||
          !sale.unitPrice.isFinite ||
          sale.unitPrice < 0 ||
          !sale.total.isFinite ||
          (sale.total - expectedTotal).abs() > 0.000001) {
        throw const AppException('Check sale quantities, prices, and totals.');
      }
      if (sale.invoiceId != invoiceId) {
        throw const AppException('All sale lines must use one invoice number.');
      }
    }
  }

  Map<String, int> _quantitiesByProduct(List<SaleModel> sales) {
    final quantities = <String, int>{};
    for (final sale in sales) {
      quantities.update(
        sale.productId,
        (value) => value + sale.quantity,
        ifAbsent: () => sale.quantity,
      );
    }
    return quantities;
  }

  Future<String?> _resolveCustomer(
    SaleModel sale,
    String? fallbackCustomerId,
  ) async {
    final name = (sale.customerName ?? '').trim();
    final phone = (sale.customerPhone ?? '').trim();
    if (name.isEmpty && phone.isEmpty) return fallbackCustomerId;
    if (name.isEmpty || phone.isEmpty) {
      throw const AppException('Customer name and phone are required.');
    }
    final existing = await customersDataSource.findByPhone(phone);
    if (existing != null) return existing.id;
    final customerId = const Uuid().v4();
    await customersDataSource.saveCustomer(
      CustomerModel(
        id: customerId,
        name: name,
        phone: phone,
        address: '',
        notes: '',
        createdAt: DateTime.now(),
      ),
    );
    return customerId;
  }

  Future<void> _applyWarehouseQuantityChanges(
    Map<String, int> oldQuantities,
    Map<String, int> newQuantities,
  ) async {
    final productIds = {...oldQuantities.keys, ...newQuantities.keys};
    final products = <String, MedicineModel>{};
    for (final productId in productIds) {
      final product = await productsDataSource.getById(productId);
      if (product == null) throw const AppException('Product was not found.');
      final available = product.quantity + (oldQuantities[productId] ?? 0);
      if (available < (newQuantities[productId] ?? 0)) {
        throw const AppException('Not enough warehouse stock.');
      }
      products[productId] = product;
    }
    for (final productId in productIds) {
      final product = products[productId]!;
      await productsDataSource.save(
        product.copyWith(
          quantity:
              product.quantity +
              (oldQuantities[productId] ?? 0) -
              (newQuantities[productId] ?? 0),
        ),
      );
    }
  }

  Future<void> _applyRepresentativeQuantityChanges(
    String representativeId,
    Map<String, int> oldQuantities,
    Map<String, int> newQuantities,
  ) async {
    final productIds = {...oldQuantities.keys, ...newQuantities.keys};
    final inventoryByProduct = <String, RepresentativeInventoryModel>{};
    for (final productId in productIds) {
      if (await productsDataSource.getById(productId) == null) {
        throw const AppException('Product was not found.');
      }
      final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
        representativeId: representativeId,
        productId: productId,
      );
      if (inventory == null) {
        throw const AppException('Representative inventory was not found.');
      }
      final updatedSold =
          inventory.quantitySold -
          (oldQuantities[productId] ?? 0) +
          (newQuantities[productId] ?? 0);
      if (updatedSold < 0 || updatedSold > inventory.quantityAssigned) {
        throw const AppException('Not enough representative stock.');
      }
      inventoryByProduct[productId] = inventory;
    }
    for (final productId in productIds) {
      final inventory = inventoryByProduct[productId]!;
      await inventoryDataSource.save(
        inventory.copyWith(
          quantitySold:
              inventory.quantitySold -
              (oldQuantities[productId] ?? 0) +
              (newQuantities[productId] ?? 0),
        ),
      );
    }
  }

  Future<void> _replaceInvoiceLines({
    required List<SaleModel> oldSales,
    required List<SaleModel> newSales,
    required String canonicalInvoiceId,
    required String? customerId,
    required double amountPaid,
    required Map<String, double> originalCosts,
  }) async {
    for (final oldSale in oldSales) {
      await salesDataSource.delete(oldSale.id);
    }
    var remainingPaid = amountPaid;
    for (final sale in newSales) {
      final product = await productsDataSource.getById(sale.productId);
      final linePaid = remainingPaid.clamp(0, sale.total).toDouble();
      remainingPaid -= linePaid;
      await salesDataSource.save(
        sale.copyWith(
          invoiceId: canonicalInvoiceId,
          date: oldSales.first.date,
          customerId: customerId,
          customerName: sale.customerName,
          customerPhone: sale.customerPhone,
          amountPaid: sale.saleType == SaleType.direct ? linePaid : 0,
          unitCost:
              originalCosts[sale.productId] ?? product?.purchasePrice ?? 0,
        ),
      );
    }
  }

  Future<void> _syncCustomerDebt({
    required String invoiceId,
    required String? customerId,
    required double invoiceTotal,
    required double amountPaid,
    required DateTime invoiceDate,
  }) async {
    final debts = (await customersDataSource.getDebts())
        .where((debt) => debt.invoiceId == invoiceId)
        .toList();
    final remaining = invoiceTotal - amountPaid;
    if (remaining <= 0.000001) {
      for (final debt in debts) {
        await customersDataSource.deleteDebt(debt.id);
      }
      return;
    }
    if (customerId == null) {
      throw const AppException('A customer is required for a partial payment.');
    }
    final now = DateTime.now();
    final existing = debts.firstOrNull;
    await customersDataSource.saveDebt(
      CustomerDebtModel(
        id: existing?.id ?? const Uuid().v4(),
        customerId: customerId,
        invoiceId: invoiceId,
        invoiceTotal: invoiceTotal,
        paidAmount: amountPaid,
        remainingAmount: remaining,
        status: DebtStatus.pending,
        createdAt: existing?.createdAt ?? invoiceDate,
        updatedAt: now,
      ),
    );
    for (final duplicate in debts.skip(1)) {
      await customersDataSource.deleteDebt(duplicate.id);
    }
  }

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final sales = (await salesDataSource.getAll())
        .where((sale) => sale.invoiceId == invoiceId || sale.id == invoiceId)
        .toList();
    if (sales.isEmpty) throw const AppException('Invoice was not found.');
    final canonicalInvoiceId = sales.first.invoiceId ?? sales.first.id;
    if (sales.first.saleType == SaleType.representative &&
        await representativeCollectionsDataSource.hasInvoiceCollections(
          canonicalInvoiceId,
        )) {
      throw const AppException(
        'A representative sale with recorded collections cannot be cancelled.',
      );
    }
    final debts = (await customersDataSource.getDebts())
        .where((debt) => debt.invoiceId == canonicalInvoiceId)
        .toList();
    final payments = await customersDataSource.getPayments();
    if (debts.any(
      (debt) => payments.any((payment) => payment.debtId == debt.id),
    )) {
      throw const AppException(
        'Invoices with recorded payments cannot be cancelled.',
      );
    }
    for (final sale in sales) {
      if (sale.saleType == SaleType.direct) {
        final product = await productsDataSource.getById(sale.productId);
        if (product == null) throw const AppException('Product was not found.');
        await productsDataSource.save(
          product.copyWith(quantity: product.quantity + sale.quantity),
        );
      } else {
        final inventory = await inventoryDataSource
            .getByRepresentativeAndProduct(
              representativeId: sale.representativeId!,
              productId: sale.productId,
            );
        if (inventory == null || inventory.quantitySold < sale.quantity) {
          throw const AppException(
            'Representative inventory could not be restored.',
          );
        }
        await inventoryDataSource.save(
          inventory.copyWith(
            quantitySold: inventory.quantitySold - sale.quantity,
          ),
        );
      }
      await salesDataSource.delete(sale.id);
    }
    for (final debt in debts) {
      await customersDataSource.deleteDebt(debt.id);
    }
  }
}
