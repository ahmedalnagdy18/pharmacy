import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/customers/data/data_source/customers_local_data_source.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:pharmacy/features/expenses/data/data_source/expenses_local_data_source.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/data/repositories/products_repository_impl.dart';
import 'package:pharmacy/features/purchases/data/data_source/purchases_local_data_source.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/data_source/representative_collections_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/data_source/representatives_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:pharmacy/features/suppliers/data/data_source/suppliers_local_data_source.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';

void main() {
  late Directory tempDirectory;
  late Box<MedicineModel> productsBox;
  late Box<RepresentativeModel> representativesBox;
  late Box<RepresentativeInventoryModel> inventoryBox;
  late Box<SaleModel> salesBox;
  late Box<CustomerModel> customersBox;
  late Box<CustomerDebtModel> customerDebtsBox;
  late Box<CustomerPaymentModel> customerPaymentsBox;
  late Box<SupplierModel> suppliersBox;
  late Box<PurchaseModel> purchasesBox;
  late Box<SupplierDebtModel> supplierDebtsBox;
  late Box<SupplierPaymentModel> supplierPaymentsBox;
  late Box<ExpenseModel> expensesBox;
  late Box<RepresentativeCollectionModel> collectionsBox;

  late ProductsLocalDataSource productsSource;
  late RepresentativesLocalDataSource representativesSource;
  late RepresentativeInventoryLocalDataSource inventorySource;
  late SalesLocalDataSource salesSource;
  late CustomersLocalDataSource customersSource;
  late SuppliersLocalDataSource suppliersSource;
  late PurchasesLocalDataSource purchasesSource;
  late ExpensesLocalDataSource expensesSource;
  late RepresentativeCollectionsLocalDataSource collectionsSource;
  late SalesRepositoryImpl salesRepository;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('pharmacy_test_');
    Hive.init(tempDirectory.path);
    _registerAdapters();
    productsBox = await Hive.openBox<MedicineModel>('test_products');
    representativesBox = await Hive.openBox<RepresentativeModel>(
      'test_representatives',
    );
    inventoryBox = await Hive.openBox<RepresentativeInventoryModel>(
      'test_inventory',
    );
    salesBox = await Hive.openBox<SaleModel>('test_sales');
    customersBox = await Hive.openBox<CustomerModel>('test_customers');
    customerDebtsBox = await Hive.openBox<CustomerDebtModel>(
      'test_customer_debts',
    );
    customerPaymentsBox = await Hive.openBox<CustomerPaymentModel>(
      'test_customer_payments',
    );
    suppliersBox = await Hive.openBox<SupplierModel>('test_suppliers');
    purchasesBox = await Hive.openBox<PurchaseModel>('test_purchases');
    supplierDebtsBox = await Hive.openBox<SupplierDebtModel>(
      'test_supplier_debts',
    );
    supplierPaymentsBox = await Hive.openBox<SupplierPaymentModel>(
      'test_supplier_payments',
    );
    expensesBox = await Hive.openBox<ExpenseModel>('test_expenses');
    collectionsBox = await Hive.openBox<RepresentativeCollectionModel>(
      'test_collections',
    );

    productsSource = ProductsLocalDataSource(productsBox);
    representativesSource = RepresentativesLocalDataSource(representativesBox);
    inventorySource = RepresentativeInventoryLocalDataSource(inventoryBox);
    salesSource = SalesLocalDataSource(salesBox);
    customersSource = CustomersLocalDataSource(
      customersBox,
      customerDebtsBox,
      customerPaymentsBox,
    );
    suppliersSource = SuppliersLocalDataSource(
      suppliersBox,
      supplierDebtsBox,
      supplierPaymentsBox,
    );
    purchasesSource = PurchasesLocalDataSource(purchasesBox);
    expensesSource = ExpensesLocalDataSource(expensesBox);
    collectionsSource = RepresentativeCollectionsLocalDataSource(
      collectionsBox,
    );
    salesRepository = SalesRepositoryImpl(
      salesDataSource: salesSource,
      productsDataSource: productsSource,
      inventoryDataSource: inventorySource,
      customersDataSource: customersSource,
      representativeCollectionsDataSource: collectionsSource,
    );
  });

  setUp(() async {
    await Future.wait([
      productsBox.clear(),
      representativesBox.clear(),
      inventoryBox.clear(),
      salesBox.clear(),
      customersBox.clear(),
      customerDebtsBox.clear(),
      customerPaymentsBox.clear(),
      suppliersBox.clear(),
      purchasesBox.clear(),
      supplierDebtsBox.clear(),
      supplierPaymentsBox.clear(),
      expensesBox.clear(),
      collectionsBox.clear(),
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('duplicate sale lines cannot exceed combined warehouse stock', () async {
    await productsSource.save(_product('p1', quantity: 10));

    await expectLater(
      salesRepository.createDirectSales([
        _sale('line-1', 'invoice-1', 'p1', quantity: 6, amountPaid: 120),
        _sale('line-2', 'invoice-1', 'p1', quantity: 6),
      ]),
      throwsA(isA<AppException>()),
    );

    expect((await productsSource.getById('p1'))!.quantity, 10);
    expect(await salesSource.getAll(), isEmpty);
  });

  test('sale total must equal quantity multiplied by unit price', () async {
    await productsSource.save(_product('p1', quantity: 10));
    final invalid = SaleModel(
      id: 'line-1',
      productId: 'p1',
      quantity: 2,
      unitPrice: 10,
      total: 999,
      date: DateTime.now(),
      saleType: SaleType.direct,
      representativeId: null,
      invoiceId: 'invoice-1',
      amountPaid: 20,
    );

    await expectLater(
      salesRepository.createDirectSales([invalid]),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'editing an invoice updates stock, debt, sales, and dashboard',
    () async {
      await productsSource.save(_product('p1', quantity: 10));
      await productsSource.save(_product('p2', quantity: 10, price: 5));
      await salesRepository.createDirectSales([
        _sale('old-line', 'invoice-1', 'p1', quantity: 4, amountPaid: 40),
      ]);

      await salesRepository.updateInvoice(
        'invoice-1',
        [
          _sale(
            'new-line-1',
            'invoice-1',
            'p1',
            quantity: 2,
            customerName: 'Customer',
            customerPhone: '0100',
          ),
          _sale(
            'new-line-2',
            'invoice-1',
            'p2',
            quantity: 3,
            price: 5,
            customerName: 'Customer',
            customerPhone: '0100',
          ),
        ],
        amountPaid: 20,
      );

      expect((await productsSource.getById('p1'))!.quantity, 8);
      expect((await productsSource.getById('p2'))!.quantity, 7);
      expect(await salesSource.getAll(), hasLength(2));
      final debt = (await customersSource.getDebts()).single;
      expect(debt.invoiceTotal, 35);
      expect(debt.paidAmount, 20);
      expect(debt.remainingAmount, 15);

      final stats = await _dashboardRepository(
        productsSource: productsSource,
        representativesSource: representativesSource,
        salesSource: salesSource,
        customersSource: customersSource,
        suppliersSource: suppliersSource,
        expensesSource: expensesSource,
        purchasesSource: purchasesSource,
        collectionsSource: collectionsSource,
      ).getStats();
      expect(stats.todaySales, 35);
    },
  );

  test(
    'representative collection cannot exceed fresh outstanding balance',
    () async {
      await productsSource.save(_product('p1', quantity: 0));
      await inventorySource.save(
        const RepresentativeInventoryModel(
          id: 'inventory-1',
          representativeId: 'rep-1',
          productId: 'p1',
          quantityAssigned: 10,
          quantitySold: 0,
        ),
      );
      await salesRepository.createRepresentativeSales([
        _sale(
          'line-1',
          'invoice-1',
          'p1',
          quantity: 5,
          saleType: SaleType.representative,
          representativeId: 'rep-1',
          customerName: 'Customer',
          customerPhone: '0100',
        ),
      ]);
      await salesRepository.recordRepresentativeCollection(
        id: 'collection-1',
        representativeId: 'rep-1',
        invoiceId: 'invoice-1',
        amount: 30,
      );

      await expectLater(
        salesRepository.recordRepresentativeCollection(
          id: 'collection-2',
          representativeId: 'rep-1',
          invoiceId: 'invoice-1',
          amount: 25,
        ),
        throwsA(isA<AppException>()),
      );
      expect(await collectionsSource.getAll(), hasLength(1));
    },
  );

  test(
    'representative invoice edit adjusts inventory and respects collections',
    () async {
      await productsSource.save(_product('p1', quantity: 0));
      await inventorySource.save(
        const RepresentativeInventoryModel(
          id: 'inventory-1',
          representativeId: 'rep-1',
          productId: 'p1',
          quantityAssigned: 10,
          quantitySold: 0,
        ),
      );
      await salesRepository.createRepresentativeSales([
        _sale(
          'line-1',
          'invoice-1',
          'p1',
          quantity: 5,
          saleType: SaleType.representative,
          representativeId: 'rep-1',
          customerName: 'Customer',
          customerPhone: '0100',
        ),
      ]);
      await salesRepository.recordRepresentativeCollection(
        id: 'collection-1',
        representativeId: 'rep-1',
        invoiceId: 'invoice-1',
        amount: 40,
      );

      await salesRepository.updateInvoice(
        'invoice-1',
        [
          _sale(
            'line-2',
            'invoice-1',
            'p1',
            quantity: 6,
            saleType: SaleType.representative,
            representativeId: 'rep-1',
            customerName: 'Customer',
            customerPhone: '0100',
          ),
        ],
        amountPaid: 40,
      );
      expect(
        (await inventorySource.getById('inventory-1'))!.quantitySold,
        6,
      );

      await expectLater(
        salesRepository.updateInvoice(
          'invoice-1',
          [
            _sale(
              'line-3',
              'invoice-1',
              'p1',
              quantity: 3,
              saleType: SaleType.representative,
              representativeId: 'rep-1',
              customerName: 'Customer',
              customerPhone: '0100',
            ),
          ],
          amountPaid: 40,
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        (await inventorySource.getById('inventory-1'))!.quantitySold,
        6,
      );
    },
  );

  test(
    'cancelling by a sale line id removes the canonical invoice debt',
    () async {
      await productsSource.save(_product('p1', quantity: 10));
      await salesRepository.createDirectSales([
        _sale(
          'line-1',
          'invoice-1',
          'p1',
          quantity: 2,
          amountPaid: 5,
          customerName: 'Customer',
          customerPhone: '0100',
        ),
      ]);
      expect(await customersSource.getDebts(), hasLength(1));

      await salesRepository.cancelInvoice('line-1');

      expect(await customersSource.getDebts(), isEmpty);
      expect(await salesSource.getAll(), isEmpty);
      expect((await productsSource.getById('p1'))!.quantity, 10);
    },
  );

  test(
    'all-time dashboard total and monthly total use the correct periods',
    () async {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 10);
      await productsSource.save(_product('p1', quantity: 10));
      await salesSource.save(
        _sale('line-1', 'invoice-1', 'p1', quantity: 2, date: now),
      );
      await salesSource.save(
        _sale(
          'line-2',
          'invoice-2',
          'p1',
          quantity: 3,
          date: previousMonth,
        ),
      );

      final repository = _dashboardRepository(
        productsSource: productsSource,
        representativesSource: representativesSource,
        salesSource: salesSource,
        customersSource: customersSource,
        suppliersSource: suppliersSource,
        expensesSource: expensesSource,
        purchasesSource: purchasesSource,
        collectionsSource: collectionsSource,
      );
      final allTime = await repository.getStats();

      expect(allTime.todaySales, 50);
      expect(allTime.monthlySales, 20);
      final selectedDay = await repository.getStats(date: previousMonth);
      expect(selectedDay.todaySales, 30);
      expect(selectedDay.monthlySales, 30);
    },
  );

  test('product with historical activity cannot be deleted', () async {
    await productsSource.save(_product('p1', quantity: 10));
    await salesSource.save(_sale('line-1', 'invoice-1', 'p1'));
    final repository = ProductsRepositoryImpl(
      productsSource,
      salesDataSource: salesSource,
      purchasesDataSource: purchasesSource,
      inventoryDataSource: inventorySource,
    );

    await expectLater(
      repository.deleteProduct('p1'),
      throwsA(isA<AppException>()),
    );
    expect(await productsSource.getById('p1'), isNotNull);
  });
}

MedicineModel _product(
  String id, {
  required int quantity,
  double price = 10,
}) => MedicineModel(
  id: id,
  name: id,
  category: 'Category',
  barcode: 'barcode-$id',
  quantity: quantity,
  purchasePrice: 4,
  sellingPrice: price,
  notes: '',
  createdAt: DateTime.now(),
);

SaleModel _sale(
  String id,
  String invoiceId,
  String productId, {
  int quantity = 1,
  double price = 10,
  double? amountPaid,
  String saleType = SaleType.direct,
  String? representativeId,
  String? customerName,
  String? customerPhone,
  DateTime? date,
}) => SaleModel(
  id: id,
  productId: productId,
  quantity: quantity,
  unitPrice: price,
  total: quantity * price,
  date: date ?? DateTime.now(),
  saleType: saleType,
  representativeId: representativeId,
  invoiceId: invoiceId,
  amountPaid: amountPaid,
  customerName: customerName,
  customerPhone: customerPhone,
);

DashboardRepositoryImpl _dashboardRepository({
  required ProductsLocalDataSource productsSource,
  required RepresentativesLocalDataSource representativesSource,
  required SalesLocalDataSource salesSource,
  required CustomersLocalDataSource customersSource,
  required SuppliersLocalDataSource suppliersSource,
  required ExpensesLocalDataSource expensesSource,
  required PurchasesLocalDataSource purchasesSource,
  required RepresentativeCollectionsLocalDataSource collectionsSource,
}) => DashboardRepositoryImpl(
  productsDataSource: productsSource,
  representativesDataSource: representativesSource,
  salesDataSource: salesSource,
  customersDataSource: customersSource,
  suppliersDataSource: suppliersSource,
  expensesDataSource: expensesSource,
  purchasesDataSource: purchasesSource,
  representativeCollectionsDataSource: collectionsSource,
);

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter(MedicineModelAdapter());
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(RepresentativeModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(RepresentativeInventoryModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SaleModelAdapter());
  if (!Hive.isAdapterRegistered(4))
    Hive.registerAdapter(CustomerModelAdapter());
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(CustomerDebtModelAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(CustomerPaymentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7))
    Hive.registerAdapter(SupplierModelAdapter());
  if (!Hive.isAdapterRegistered(8))
    Hive.registerAdapter(PurchaseModelAdapter());
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(SupplierDebtModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(SupplierPaymentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(11))
    Hive.registerAdapter(ExpenseModelAdapter());
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(RepresentativeCollectionModelAdapter());
  }
}
