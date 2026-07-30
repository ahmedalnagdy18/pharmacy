import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/database/hive_service.dart';
import 'package:pharmacy/core/di/app_dependencies.dart';
import 'package:pharmacy/core/presentation/cubits/app_data_cubit.dart';
import 'package:pharmacy/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/reports/domain/usecases/report_usecases.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_cubit.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_cubit.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(MyApp(dependencies: AppDependencies()));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ReportsUseCases>.value(
      value: dependencies.reportsUseCases,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProductsCubit(
              getProducts: dependencies.getProducts,
              saveProduct: dependencies.saveProduct,
              deleteProduct: dependencies.deleteProduct,
            )..load(),
          ),
          BlocProvider(
            create: (_) => RepresentativesCubit(
              getRepresentatives: dependencies.getRepresentatives,
              saveRepresentative: dependencies.saveRepresentative,
              deleteRepresentative: dependencies.deleteRepresentative,
            )..load(),
          ),
          BlocProvider(
            create: (_) => RepresentativeInventoryCubit(
              getInventory: dependencies.getInventory,
              assignInventory: dependencies.assignInventory,
            )..load(),
          ),
          BlocProvider(
            create: (_) => SalesCubit(
              getSales: dependencies.getSales,
              createDirectSale: dependencies.createDirectSale,
              createRepresentativeSale: dependencies.createRepresentativeSale,
              cancelSaleInvoice: dependencies.cancelSaleInvoice,
              searchAndFilterSales: dependencies.searchAndFilterSales,
            )..load(),
          ),
          BlocProvider(
            create: (_) =>
                DashboardCubit(dependencies.getDashboardStats)..load(),
          ),
          BlocProvider(
            create: (_) => AppDataCubit(dependencies.clearAppData),
          ),
          BlocProvider(
            create: (_) =>
                CustomersCubit(dependencies.customerUseCases)..load(),
          ),
          BlocProvider(
            create: (_) =>
                SuppliersCubit(dependencies.supplierUseCases)..load(),
          ),
          BlocProvider(
            create: (_) =>
                PurchasesCubit(dependencies.purchaseUseCases)..load(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF10B4B6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
            cardTheme: const CardThemeData(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          home: const DashboardPage(),
        ),
      ),
    );
  }
}
