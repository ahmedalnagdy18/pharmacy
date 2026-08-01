import 'package:flutter/material.dart';
import 'package:pharmacy/widgets/app_formatters.dart';

enum DateFilter { allTime, today, yesterday, custom }

class DateFilterBar extends StatelessWidget {
  const DateFilterBar({
    required this.value,
    required this.customDate,
    required this.onChanged,
    super.key,
  });

  final DateFilter value;
  final DateTime? customDate;
  final ValueChanged<DateFilterSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<DateFilter>(
          segments: const [
            ButtonSegment(value: DateFilter.allTime, label: Text('All time')),
            ButtonSegment(value: DateFilter.today, label: Text('Today')),
            ButtonSegment(
              value: DateFilter.yesterday,
              label: Text('Yesterday'),
            ),
            ButtonSegment(value: DateFilter.custom, label: Text('Date')),
          ],
          selected: {value},
          onSelectionChanged: (selection) async {
            final filter = selection.first;
            if (filter != DateFilter.custom) {
              onChanged(DateFilterSelection(filter));
              return;
            }
            final selected = await showDatePicker(
              context: context,
              initialDate: customDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (selected != null) {
              onChanged(DateFilterSelection(filter, selected));
            }
          },
        ),
        if (value == DateFilter.custom && customDate != null)
          Text(AppFormatters.date.format(customDate!)),
      ],
    );
  }
}

class DateFilterSelection {
  const DateFilterSelection(this.filter, [this.customDate]);

  final DateFilter filter;
  final DateTime? customDate;
}

bool matchesDateFilter(
  DateTime date,
  DateFilter filter,
  DateTime? customDate,
) {
  if (filter == DateFilter.allTime) return true;
  final now = DateTime.now();
  final target = switch (filter) {
    DateFilter.today => now,
    DateFilter.yesterday => now.subtract(const Duration(days: 1)),
    DateFilter.custom => customDate,
    DateFilter.allTime => null,
  };
  return target != null &&
      date.year == target.year &&
      date.month == target.month &&
      date.day == target.day;
}
