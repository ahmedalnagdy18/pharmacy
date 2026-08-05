import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/purchases/data/data_source/purchases_local_data_source.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/purchases/domain/repositories/purchases_repository.dart';
import 'package:pharmacy/features/suppliers/data/data_source/suppliers_local_data_source.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:uuid/uuid.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  const PurchasesRepositoryImpl({
    required this.purchasesSource,
    required this.productsSource,
    required this.suppliersSource,
  });
  final PurchasesLocalDataSource purchasesSource;
  final ProductsLocalDataSource productsSource;
  final SuppliersLocalDataSource suppliersSource;
  @override
  Future<List<PurchaseModel>> purchases() => purchasesSource.getAll();
  @override
  Future<void> create(List<PurchaseModel> purchases) async {
    if (purchases.isEmpty)
      throw const AppException('Add at least one medicine.');
    final firstPurchase = purchases.first;
    final invoiceTotal = purchases.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final invoicePaid = firstPurchase.paidAmount;
    if (!invoiceTotal.isFinite ||
        !invoicePaid.isFinite ||
        invoicePaid < 0 ||
        invoicePaid > invoiceTotal) {
      throw const AppException('Check purchase quantities and amounts.');
    }
    if (!(await suppliersSource.getSuppliers()).any(
      (s) => s.id == firstPurchase.supplierId,
    )) {
      throw const AppException('Supplier was not found.');
    }
    for (final purchase in purchases) {
      if (purchase.supplierId != firstPurchase.supplierId ||
          purchase.quantity <= 0 ||
          !purchase.unitCost.isFinite ||
          purchase.unitCost < 0 ||
          !purchase.total.isFinite ||
          (purchase.total - purchase.quantity * purchase.unitCost).abs() >
              0.000001) {
        throw const AppException('Check purchase quantities and amounts.');
      }
      if (await productsSource.getById(purchase.productId) == null) {
        throw const AppException('Product was not found.');
      }
    }
    var remainingPaid = invoicePaid;
    for (final purchase in purchases) {
      final product = await productsSource.getById(purchase.productId);
      await productsSource.save(
        product!.copyWith(
          quantity: product.quantity + purchase.quantity,
          purchasePrice: purchase.unitCost,
        ),
      );
      final linePaid = remainingPaid.clamp(0, purchase.total).toDouble();
      remainingPaid -= linePaid;
      await purchasesSource.save(purchase.copyWith(paidAmount: linePaid));
    }
    final remaining = invoiceTotal - invoicePaid;
    if (remaining > 0) {
      await suppliersSource.saveDebt(
        SupplierDebtModel(
          id: const Uuid().v4(),
          supplierId: firstPurchase.supplierId,
          purchaseId: firstPurchase.invoiceId ?? firstPurchase.id,
          invoiceTotal: invoiceTotal,
          paidAmount: invoicePaid,
          remainingAmount: remaining,
          status: DebtStatus.pending,
          date: firstPurchase.date,
        ),
      );
    }
  }

  /*
    if (purchase.quantity <= 0 ||
        purchase.unitCost < 0 ||
        purchase.paidAmount < 0 ||
        purchase.paidAmount > purchase.total)
      throw const AppException('Check purchase quantities and amounts.');
    final product = await productsSource.getById(purchase.productId);
    if (product == null) throw const AppException('Product was not found.');
    if (!(await suppliersSource.getSuppliers()).any(
      (s) => s.id == purchase.supplierId,
    ))
      throw const AppException('Supplier was not found.');
    await productsSource.save(
      product.copyWith(
        quantity: product.quantity + purchase.quantity,
        purchasePrice: purchase.unitCost,
      ),
    );
    await purchasesSource.save(purchase);
    final remaining = purchase.total - purchase.paidAmount;
    if (remaining > 0) {
      await suppliersSource.saveDebt(
        SupplierDebtModel(
          id: const Uuid().v4(),
          supplierId: purchase.supplierId,
          purchaseId: purchase.id,
          invoiceTotal: purchase.total,
          paidAmount: purchase.paidAmount,
          remainingAmount: remaining,
          status: DebtStatus.pending,
          date: purchase.date,
        ),
      );
    }
  }
  */
}
