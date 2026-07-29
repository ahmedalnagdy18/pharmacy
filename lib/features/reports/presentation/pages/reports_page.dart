import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_state.dart';
import 'package:pharmacy/widgets/app_formatters.dart';
import 'package:pharmacy/widgets/app_stat_card.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

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
                    'Reports',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () => context.read<DashboardCubit>().load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is DashboardLoaded)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppStatCard(
                                title: 'Daily sales',
                                value: AppFormatters.currency.format(
                                  state.stats.todaySales,
                                ),
                                icon: Icons.today_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppStatCard(
                                title: 'Monthly sales',
                                value: AppFormatters.currency.format(
                                  state.stats.monthlySales,
                                ),
                                icon: Icons.calendar_month_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppStatCard(
                                title: 'Inventory value',
                                value: AppFormatters.currency.format(
                                  state.stats.inventoryValue,
                                ),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ReportTable(
                          title: 'Top medicines',
                          columns: const ['Medicine', 'Sold', 'Sales'],
                          rows: state.stats.topSellingMedicines
                              .map(
                                (item) => [
                                  item.product.name,
                                  item.quantitySold.toString(),
                                  AppFormatters.currency.format(
                                    item.totalSales,
                                  ),
                                ],
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _ReportTable(
                          title: 'Top representatives',
                          columns: const ['Representative', 'Sold', 'Sales'],
                          rows: state.stats.topRepresentatives
                              .map(
                                (item) => [
                                  item.representative.name,
                                  item.quantitySold.toString(),
                                  AppFormatters.currency.format(
                                    item.totalSales,
                                  ),
                                ],
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is DashboardLoading)
                const LinearProgressIndicator()
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
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
