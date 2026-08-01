import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/widgets/app_stat_card.dart';
import 'package:pharmacy/widgets/date_filter_bar.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});
  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  DateFilter _dateFilter = DateFilter.today;
  DateTime? _customDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  DateFilterBar(
                    value: _dateFilter,
                    customDate: _customDate,
                    onChanged: (selection) {
                      setState(() {
                        _dateFilter = selection.filter;
                        _customDate = selection.customDate;
                      });
                      _loadStats();
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is DashboardLoading)
                const LinearProgressIndicator()
              else
                const SizedBox(height: 4),
              const SizedBox(height: 12),
              if (state is DashboardLoaded)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width > 1100
                                ? 4
                                : width > 720
                                ? 2
                                : 1;
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: crossAxisCount == 1 ? 4 : 2.6,
                              children: [
                                AppStatCard(
                                  title: 'Products',
                                  value: state.stats.totalProducts.toString(),
                                  icon: Icons.medication_outlined,
                                ),
                                AppStatCard(
                                  title: 'Warehouse quantity',
                                  value: state.stats.totalWarehouseQuantity
                                      .toString(),
                                  icon: Icons.inventory_2_outlined,
                                ),
                                AppStatCard(
                                  title: 'Inventory value',
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.inventoryValue,
                                  ),
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                AppStatCard(
                                  title: 'Today sales',
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.todaySales,
                                  ),
                                  icon: Icons.today_outlined,
                                ),
                                AppStatCard(
                                  title: 'Monthly sales',
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.monthlySales,
                                  ),
                                  icon: Icons.calendar_month_outlined,
                                ),
                                AppStatCard(
                                  title: 'Low stock',
                                  value: state.stats.lowStockProducts.length
                                      .toString(),
                                  icon: Icons.warning_amber_outlined,
                                ),
                                AppStatCard(
                                  title: 'Customer debts',
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.outstandingCustomerDebts,
                                  ),
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                AppStatCard(
                                  title: 'Supplier debts',
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.outstandingSupplierDebts,
                                  ),
                                  icon: Icons.receipt_long_outlined,
                                ),
                                AppStatCard(
                                  title: "Today's collections",
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.todayCollections,
                                  ),
                                  icon: Icons.payments_outlined,
                                ),
                                AppStatCard(
                                  title: "Today's payments",
                                  value: AppFormatters.compactCurrency.format(
                                    state.stats.todayPayments,
                                  ),
                                  icon: Icons.outbox_outlined,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SummaryTable(
                                title: 'Top medicines',
                                columns: const ['Medicine', 'Qty', 'Total'],
                                rows: state.stats.topSellingMedicines
                                    .map(
                                      (item) => [
                                        item.product.name,
                                        item.quantitySold.toString(),
                                        AppFormatters.compactCurrency.format(
                                          item.totalSales,
                                        ),
                                      ],
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryTable(
                                title: 'Top representatives',
                                columns: const [
                                  'Representative',
                                  'Qty',
                                  'Total',
                                ],
                                rows: state.stats.topRepresentatives
                                    .map(
                                      (item) => [
                                        item.representative.name,
                                        item.quantitySold.toString(),
                                        AppFormatters.compactCurrency.format(
                                          item.totalSales,
                                        ),
                                      ],
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SummaryTable(
                          title: 'Low stock products',
                          columns: const ['Medicine', 'Category', 'Qty'],
                          rows: state.stats.lowStockProducts
                              .map(
                                (item) => [
                                  item.name,
                                  item.category,
                                  item.quantity.toString(),
                                ],
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is DashboardError)
                Text(state.message)
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }

  void _loadStats() {
    final date = switch (_dateFilter) {
      DateFilter.today => DateTime.now(),
      DateFilter.yesterday => DateTime.now().subtract(const Duration(days: 1)),
      DateFilter.custom => _customDate ?? DateTime.now(),
      DateFilter.allTime => null,
    };
    context.read<DashboardCubit>().load(
      date: date,
      allTime: _dateFilter == DateFilter.allTime,
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns
                    .map((column) => DataColumn(label: Text(column)))
                    .toList(),
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: row.map((cell) => DataCell(Text(cell))).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
