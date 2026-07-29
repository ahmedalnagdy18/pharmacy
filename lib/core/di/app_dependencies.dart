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
      productsDataSource: productsDataSource,
      inventoryDataSource: inventoryDataSource,
    );
    dashboardRepository = DashboardRepositoryImpl(
      productsDataSource: productsDataSource,
      representativesDataSource: representativesDataSource,
      salesDataSource: salesDataSource,
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
    searchAndFilterSales = SearchAndFilterSalesUseCase(salesRepository);
    getDashboardStats = GetDashboardStatsUseCase(dashboardRepository);
    clearAppData = ClearAppDataUseCase(appDataRepository);
    reportsUseCases = ReportsUseCases(
      dashboardRepository: dashboardRepository,
      salesRepository: salesRepository,
    );
  }

  late final ProductsLocalDataSource productsDataSource;
  late final RepresentativesLocalDataSource representativesDataSource;
  late final RepresentativeInventoryLocalDataSource inventoryDataSource;
  late final SalesLocalDataSource salesDataSource;

  late final ProductsRepositoryImpl productsRepository;
  late final RepresentativesRepositoryImpl representativesRepository;
  late final RepresentativeInventoryRepositoryImpl inventoryRepository;
  late final SalesRepositoryImpl salesRepository;
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
  late final SearchAndFilterSalesUseCase searchAndFilterSales;
  late final GetDashboardStatsUseCase getDashboardStats;
  late final ClearAppDataUseCase clearAppData;
  late final ReportsUseCases reportsUseCases;
}
