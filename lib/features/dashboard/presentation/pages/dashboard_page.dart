import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/core/presentation/cubits/app_data_cubit.dart';
import 'package:pharmacy/core/presentation/cubits/app_data_state.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_state.dart';
import 'package:pharmacy/features/dashboard/presentation/widgets/dashboard_overview.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_cubit.dart';
import 'package:pharmacy/features/products/presentation/cubits/products_state.dart';
import 'package:pharmacy/features/products/presentation/pages/products_page.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_cubit.dart';
import 'package:pharmacy/features/representative_inventory/presentation/cubits/representative_inventory_state.dart';
import 'package:pharmacy/features/representative_inventory/presentation/pages/representative_inventory_page.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';
import 'package:pharmacy/features/representatives/presentation/pages/representatives_page.dart';
import 'package:pharmacy/features/reports/presentation/pages/reports_page.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_cubit.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_state.dart';
import 'package:pharmacy/features/sales/presentation/pages/sales_page.dart';
import 'package:pharmacy/features/customers/presentation/pages/customers_page.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_cubit.dart';
import 'package:pharmacy/features/suppliers/presentation/pages/suppliers_page.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_cubit.dart';
import 'package:pharmacy/features/purchases/presentation/pages/purchases_page.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final _pages = const [
    DashboardOverview(),
    ProductsPage(),
    RepresentativesPage(),
    RepresentativeInventoryPage(),
    SalesPage(),
    CustomersPage(),
    SuppliersPage(),
    PurchasesPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsCubit, ProductsState>(
          listener: _showError<ProductsState, ProductsError>(
            (state) => state.message,
          ),
        ),
        BlocListener<RepresentativesCubit, RepresentativesState>(
          listener: _showError<RepresentativesState, RepresentativesError>(
            (state) => state.message,
          ),
        ),
        BlocListener<
          RepresentativeInventoryCubit,
          RepresentativeInventoryState
        >(
          listener:
              _showError<
                RepresentativeInventoryState,
                RepresentativeInventoryError
              >(
                (state) => state.message,
              ),
        ),
        BlocListener<SalesCubit, SalesState>(
          listener: _showError<SalesState, SalesError>(
            (state) => state.message,
          ),
        ),
        BlocListener<DashboardCubit, DashboardState>(
          listener: _showError<DashboardState, DashboardError>(
            (state) => state.message,
          ),
        ),
        BlocListener<AppDataCubit, AppDataState>(
          listener: (context, state) {
            if (state is AppDataCleared) {
              _reloadAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local data was cleared.')),
              );
            } else if (state is AppDataError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compactNavigation = constraints.maxWidth < 1000;
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  labelType: compactNavigation
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: _destinations(context),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _pages[_selectedIndex]),
                      PositionedDirectional(
                        bottom: 12,
                        end: 12,
                        child: Column(
                          children: [
                            IconButton.filledTonal(
                              tooltip: context.localized(
                                'Switch language',
                                'تغيير اللغة',
                              ),
                              onPressed: () =>
                                  AppLanguageScope.of(context).toggle(),
                              icon: Text(context.isArabic ? 'EN' : 'ع'),
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<AppDataCubit, AppDataState>(
                              builder: (context, state) =>
                                  IconButton.filledTonal(
                                    tooltip: context.localized(
                                      'Clear all data',
                                      'مسح كل البيانات',
                                    ),
                                    onPressed: state is AppDataLoading
                                        ? null
                                        : () => _confirmClearAllData(context),
                                    icon: state is AppDataLoading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_sweep_outlined,
                                          ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<NavigationRailDestination> _destinations(BuildContext context) {
    return [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text(context.localized('Dashboard', 'الرئيسية')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication),
        label: Text(context.localized('Products', 'المنتجات')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.badge_outlined),
        selectedIcon: Icon(Icons.badge),
        label: Text(context.localized('Reps', 'المندوبون')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text(context.localized('Inventory', 'المخزون')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text(context.localized('Sales', 'المبيعات')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text(context.localized('Customers', 'العملاء')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.local_shipping_outlined),
        selectedIcon: Icon(Icons.local_shipping),
        label: Text(context.localized('Suppliers', 'الموردون')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: Text(context.localized('Purchases', 'المشتريات')),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: Text(context.localized('Reports', 'التقارير')),
      ),
    ];
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
      case 8:
        context.read<DashboardCubit>().load();
        break;
      case 1:
        context.read<ProductsCubit>().load();
        break;
      case 2:
        context.read<RepresentativesCubit>().load();
        break;
      case 3:
        context.read<RepresentativeInventoryCubit>().load();
        context.read<ProductsCubit>().load();
        context.read<RepresentativesCubit>().load();
        break;
      case 4:
        context.read<SalesCubit>().load();
        context.read<ProductsCubit>().load();
        context.read<RepresentativesCubit>().load();
        context.read<RepresentativeInventoryCubit>().load();
        break;
      case 5:
        context.read<CustomersCubit>().load();
        break;
      case 6:
        context.read<SuppliersCubit>().load();
        break;
      case 7:
        context.read<PurchasesCubit>().load();
        context.read<ProductsCubit>().load();
        context.read<SuppliersCubit>().load();
        break;
    }
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all data'),
        content: const Text(
          'This will delete all products, representatives, inventory, and sales from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AppDataCubit>().clearAllData();
    }
  }

  void _reloadAll() {
    context.read<ProductsCubit>().load();
    context.read<RepresentativesCubit>().load();
    context.read<RepresentativeInventoryCubit>().load();
    context.read<SalesCubit>().load();
    context.read<CustomersCubit>().load();
    context.read<SuppliersCubit>().load();
    context.read<PurchasesCubit>().load();
    context.read<DashboardCubit>().load();
  }

  BlocWidgetListener<S> _showError<S, E extends S>(
    String Function(E state) messageOf,
  ) {
    return (context, state) {
      if (state is E) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageOf(state))),
        );
      }
    };
  }
}
