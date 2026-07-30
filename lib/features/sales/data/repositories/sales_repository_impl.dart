import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/repositories/sales_repository.dart';
import 'package:pharmacy/features/customers/data/data_source/customers_local_data_source.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:uuid/uuid.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl({
    required this.salesDataSource,
    required this.productsDataSource,
    required this.inventoryDataSource,
    required this.customersDataSource,
  });

  final SalesLocalDataSource salesDataSource;
  final ProductsLocalDataSource productsDataSource;
  final RepresentativeInventoryLocalDataSource inventoryDataSource;
  final CustomersLocalDataSource customersDataSource;

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
    final firstSale = sales.first;
    final invoiceTotal = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final paid = firstSale.amountPaid ?? invoiceTotal;
    if (paid < 0 || paid > invoiceTotal) {
      throw const AppException(
        'Paid amount must be between zero and the invoice total.',
      );
    }
    String? customerId = firstSale.customerId;
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
    for (final sale in sales) {
      if (sale.quantity <= 0) {
        throw const AppException('Sale quantity must be greater than zero.');
      }
      final product = await productsDataSource.getById(sale.productId);
      if (product == null) throw const AppException('Product was not found.');
      if (product.quantity < sale.quantity) {
        throw const AppException('Not enough warehouse stock.');
      }
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
    final representativeId = sales.first.representativeId;
    if (representativeId == null || representativeId.isEmpty) {
      throw const AppException('Representative is required.');
    }

    for (final sale in sales) {
      if (sale.quantity <= 0 || sale.representativeId != representativeId) {
        throw const AppException('Check sale items and representative.');
      }
      final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
        representativeId: representativeId,
        productId: sale.productId,
      );
      if (inventory == null || inventory.remainingQuantity < sale.quantity) {
        throw const AppException('Not enough representative stock.');
      }
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
        ),
      );
    }
  }

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final sales = (await salesDataSource.getAll())
        .where((sale) => sale.invoiceId == invoiceId || sale.id == invoiceId)
        .toList();
    if (sales.isEmpty) throw const AppException('Invoice was not found.');
    final debts = (await customersDataSource.getDebts())
        .where((debt) => debt.invoiceId == invoiceId)
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
