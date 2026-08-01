import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pharmacy/core/localization/app_language.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLanguageController _languageController;

  @override
  void initState() {
    super.initState();
    _languageController = AppLanguageController();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ReportsUseCases>.value(
      value: widget.dependencies.reportsUseCases,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProductsCubit(
              getProducts: widget.dependencies.getProducts,
              saveProduct: widget.dependencies.saveProduct,
              deleteProduct: widget.dependencies.deleteProduct,
            )..load(),
          ),
          BlocProvider(
            create: (_) => RepresentativesCubit(
              getRepresentatives: widget.dependencies.getRepresentatives,
              saveRepresentative: widget.dependencies.saveRepresentative,
              deleteRepresentative: widget.dependencies.deleteRepresentative,
            )..load(),
          ),
          BlocProvider(
            create: (_) => RepresentativeInventoryCubit(
              getInventory: widget.dependencies.getInventory,
              assignInventory: widget.dependencies.assignInventory,
            )..load(),
          ),
          BlocProvider(
            create: (_) => SalesCubit(
              getSales: widget.dependencies.getSales,
              createDirectSale: widget.dependencies.createDirectSale,
              createRepresentativeSale:
                  widget.dependencies.createRepresentativeSale,
              cancelSaleInvoice: widget.dependencies.cancelSaleInvoice,
              searchAndFilterSales: widget.dependencies.searchAndFilterSales,
            )..load(),
          ),
          BlocProvider(
            create: (_) =>
                DashboardCubit(widget.dependencies.getDashboardStats)..load(),
          ),
          BlocProvider(
            create: (_) => AppDataCubit(widget.dependencies.clearAppData),
          ),
          BlocProvider(
            create: (_) =>
                CustomersCubit(widget.dependencies.customerUseCases)..load(),
          ),
          BlocProvider(
            create: (_) =>
                SuppliersCubit(widget.dependencies.supplierUseCases)..load(),
          ),
          BlocProvider(
            create: (_) =>
                PurchasesCubit(widget.dependencies.purchaseUseCases)..load(),
          ),
        ],
        child: ValueListenableBuilder<Locale>(
          valueListenable: _languageController,
          builder: (context, locale, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
            home: AppLanguageScope(
              controller: _languageController,
              child: const DashboardPage(),
            ),
          ),
        ),
      ),
    );
  }
}
