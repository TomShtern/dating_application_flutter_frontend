String formatDateTimeStamp(DateTime value, {DateTime? reference}) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';

  return '${formatShortDate(local, reference: reference)} · $hour:$minute $meridiem';
}

String formatShortDate(DateTime value, {DateTime? reference}) {
  final local = value.toLocal();
  final current = (reference ?? DateTime.now()).toLocal();
  final dateLabel = '${_monthLabel(local.month)} ${local.day}';

  if (local.year == current.year) {
    return dateLabel;
  }

  return '$dateLabel, ${local.year}';
}

String _monthLabel(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}
