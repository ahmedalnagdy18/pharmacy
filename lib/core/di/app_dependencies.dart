import 'package:hive/hive.dart';
import 'package:pharmacy/core/constants/hive_boxes.dart';
import 'package:pharmacy/core/data/repositories/app_data_repository_impl.dart';
import 'package:pharmacy/core/domain/usecases/clear_app_data_usecase.dart';
import 'package:pharmacy/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:pharmacy/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/data/repositories/products_repository_impl.dart';
import 'package:pharmacy/features/products/domain/usecases/product_usecases.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representative_inventory/data/repositories/representative_inventory_repository_impl.dart';
import 'package:pharmacy/features/representative_inventory/domain/usecases/representative_inventory_usecases.dart';
import 'package:pharmacy/features/representatives/data/data_source/representatives_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/data/repositories/representatives_repository_impl.dart';
import 'package:pharmacy/features/representatives/domain/usecases/representative_usecases.dart';
import 'package:pharmacy/features/reports/domain/usecases/report_usecases.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:pharmacy/features/sales/domain/usecases/sales_usecases.dart';
import 'package:pharmacy/features/customers/data/data_source/customers_local_data_source.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/customers/data/repositories/customers_repository_impl.dart';
import 'package:pharmacy/features/customers/domain/usecases/customer_usecases.dart';
import 'package:pharmacy/features/suppliers/data/data_source/suppliers_local_data_source.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';
import 'package:pharmacy/features/suppliers/data/repositories/suppliers_repository_impl.dart';
import 'package:pharmacy/features/suppliers/domain/usecases/supplier_usecases.dart';
import 'package:pharmacy/features/purchases/data/data_source/purchases_local_data_source.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/purchases/data/repositories/purchases_repository_impl.dart';
import 'package:pharmacy/features/purchases/domain/usecases/purchase_usecases.dart';
import 'package:pharmacy/features/expenses/data/data_source/expenses_local_data_source.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';
import 'package:pharmacy/features/expenses/domain/usecases/expense_usecases.dart';
import 'package:pharmacy/features/representatives/data/data_source/representative_collections_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';

class AppDependencies {
  AppDependencies() {
    productsDataSource = ProductsLocalDataSource(
      Hive.box<MedicineModel>(HiveBoxes.products),
    );
    representativesDataSource = RepresentativesLocalDataSource(
      Hive.box<RepresentativeModel>(HiveBoxes.representatives),
    );
    inventoryDataSource = RepresentativeInventoryLocalDataSource(
      Hive.box<RepresentativeInventoryModel>(HiveBoxes.representativeInventory),
    );
    salesDataSource = SalesLocalDataSource(
      Hive.box<SaleModel>(HiveBoxes.sales),
    );
    customersDataSource = CustomersLocalDataSource(
      Hive.box<CustomerModel>(HiveBoxes.customers),
      Hive.box<CustomerDebtModel>(HiveBoxes.customerDebts),
      Hive.box<CustomerPaymentModel>(HiveBoxes.customerPayments),
    );
    suppliersDataSource = SuppliersLocalDataSource(
      Hive.box<SupplierModel>(HiveBoxes.suppliers),
      Hive.box<SupplierDebtModel>(HiveBoxes.supplierDebts),
      Hive.box<SupplierPaymentModel>(HiveBoxes.supplierPayments),
    );
    purchasesDataSource = PurchasesLocalDataSource(
      Hive.box<PurchaseModel>(HiveBoxes.purchases),
    );
    expensesDataSource = ExpensesLocalDataSource(Hive.box<ExpenseModel>(HiveBoxes.expenses));
    representativeCollectionsDataSource = RepresentativeCollectionsLocalDataSource(Hive.box<RepresentativeCollectionModel>(HiveBoxes.representativeCollections));

    productsRepository = ProductsRepositoryImpl(productsDataSource);
    representativesRepository = RepresentativesRepositoryImpl(
      representativesDataSource,
    );
    inventoryRepository = RepresentativeInventoryRepositoryImpl(
      inventoryDataSource: inventoryDataSource,
      productsDataSource: productsDataSource,
    );
    salesRepository = SalesRepositoryImpl(
      salesDataSource: salesDataSource,
      customersDataSource: customersDataSource,
      productsDataSource: productsDataSource,
      inventoryDataSource: inventoryDataSource,
      representativeCollectionsDataSource: representativeCollectionsDataSource,
    );
    customersRepository = CustomersRepositoryImpl(
      source: customersDataSource,
      salesDataSource: salesDataSource,
    );
    suppliersRepository = SuppliersRepositoryImpl(
      source: suppliersDataSource,
      purchasesDataSource: purchasesDataSource,
    );
    purchasesRepository = PurchasesRepositoryImpl(
      purchasesSource: purchasesDataSource,
      productsSource: productsDataSource,
      suppliersSource: suppliersDataSource,
    );
    dashboardRepository = DashboardRepositoryImpl(
      productsDataSource: productsDataSource,
      representativesDataSource: representativesDataSource,
      salesDataSource: salesDataSource,
      customersDataSource: customersDataSource,
      suppliersDataSource: suppliersDataSource,
      expensesDataSource: expensesDataSource,
      purchasesDataSource: purchasesDataSource,
      representativeCollectionsDataSource: representativeCollectionsDataSource,
    );
    appDataRepository = const AppDataRepositoryImpl();

    getProducts = GetProductsUseCase(productsRepository);
    saveProduct = SaveProductUseCase(productsRepository);
    deleteProduct = DeleteProductUseCase(productsRepository);
    getRepresentatives = GetRepresentativesUseCase(representativesRepository);
    saveRepresentative = SaveRepresentativeUseCase(representativesRepository);
    deleteRepresentative = DeleteRepresentativeUseCase(
      representativesRepository,
    );
    getInventory = GetRepresentativeInventoryUseCase(inventoryRepository);
    assignInventory = AssignRepresentativeInventoryUseCase(inventoryRepository);
    getSales = GetSalesUseCase(salesRepository);
    createDirectSale = CreateDirectSaleUseCase(salesRepository);
    createRepresentativeSale = CreateRepresentativeSaleUseCase(salesRepository);
    cancelSaleInvoice = CancelSaleInvoiceUseCase(salesRepository);
    searchAndFilterSales = SearchAndFilterSalesUseCase(salesRepository);
    getDashboardStats = GetDashboardStatsUseCase(dashboardRepository);
    clearAppData = ClearAppDataUseCase(appDataRepository);
    customerUseCases = CustomerUseCases(customersRepository);
    supplierUseCases = SupplierUseCases(suppliersRepository);
    purchaseUseCases = PurchaseUseCases(purchasesRepository);
    expenseUseCases = ExpenseUseCases(expensesDataSource);
    reportsUseCases = ReportsUseCases(
      dashboardRepository: dashboardRepository,
      salesRepository: salesRepository,
    );
  }

  late final ProductsLocalDataSource productsDataSource;
  late final RepresentativesLocalDataSource representativesDataSource;
  late final RepresentativeInventoryLocalDataSource inventoryDataSource;
  late final SalesLocalDataSource salesDataSource;
  late final CustomersLocalDataSource customersDataSource;
  late final SuppliersLocalDataSource suppliersDataSource;
  late final PurchasesLocalDataSource purchasesDataSource;
  late final ExpensesLocalDataSource expensesDataSource;
  late final RepresentativeCollectionsLocalDataSource representativeCollectionsDataSource;

  late final ProductsRepositoryImpl productsRepository;
  late final RepresentativesRepositoryImpl representativesRepository;
  late final RepresentativeInventoryRepositoryImpl inventoryRepository;
  late final SalesRepositoryImpl salesRepository;
  late final CustomersRepositoryImpl customersRepository;
  late final SuppliersRepositoryImpl suppliersRepository;
  late final PurchasesRepositoryImpl purchasesRepository;
  late final DashboardRepositoryImpl dashboardRepository;
  late final AppDataRepositoryImpl appDataRepository;

  late final GetProductsUseCase getProducts;
  late final SaveProductUseCase saveProduct;
  late final DeleteProductUseCase deleteProduct;
  late final GetRepresentativesUseCase getRepresentatives;
  late final SaveRepresentativeUseCase saveRepresentative;
  late final DeleteRepresentativeUseCase deleteRepresentative;
  late final GetRepresentativeInventoryUseCase getInventory;
  late final AssignRepresentativeInventoryUseCase assignInventory;
  late final GetSalesUseCase getSales;
  late final CreateDirectSaleUseCase createDirectSale;
  late final CreateRepresentativeSaleUseCase createRepresentativeSale;
  late final CancelSaleInvoiceUseCase cancelSaleInvoice;
  late final SearchAndFilterSalesUseCase searchAndFilterSales;
  late final GetDashboardStatsUseCase getDashboardStats;
  late final ClearAppDataUseCase clearAppData;
  late final CustomerUseCases customerUseCases;
  late final SupplierUseCases supplierUseCases;
  late final PurchaseUseCases purchaseUseCases;
  late final ExpenseUseCases expenseUseCases;
  late final ReportsUseCases reportsUseCases;
}
