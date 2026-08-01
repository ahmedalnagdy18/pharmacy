import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/localization/app_language.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_cubit.dart';
import 'package:pharmacy/features/representatives/presentation/cubits/representatives_state.dart';
import 'package:pharmacy/features/representatives/presentation/widgets/representative_dialog.dart';

class RepresentativesPage extends StatelessWidget {
  const RepresentativesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepresentativesCubit, RepresentativesState>(
      builder: (context, state) {
        final representatives = state is RepresentativesLoaded
            ? state.representatives
            : const <RepresentativeModel>[];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('Representatives'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: context.tr('Refresh'),
                    onPressed: () =>
                        context.read<RepresentativesCubit>().load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add representative')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is RepresentativesLoading)
                const LinearProgressIndicator()
              else
                const SizedBox(height: 4),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(context.tr('Name'))),
                          DataColumn(label: Text(context.tr('Phone'))),
                          DataColumn(label: Text(context.tr('Actions'))),
                        ],
                        rows: representatives
                            .map((item) => _row(context, item))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataRow _row(BuildContext context, RepresentativeModel representative) {
    return DataRow(
      cells: [
        DataCell(Text(representative.name)),
        DataCell(Text(representative.phone)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openDialog(
                  context,
                  representative: representative,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, representative),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDialog(
    BuildContext context, {
    RepresentativeModel? representative,
  }) async {
    final result = await showRepresentativeDialog(
      context,
      representative: representative,
    );
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<RepresentativesCubit>().createOrUpdate(
      id: representative?.id,
      name: result.name,
      phone: result.phone,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RepresentativeModel representative,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete representative'),
        content: Text('Delete ${representative.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<RepresentativesCubit>().remove(representative.id);
    }
  }
}
