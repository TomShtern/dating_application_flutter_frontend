String formatDateTimeStamp(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';

  return '${_monthLabel(local.month)} ${local.day}, ${local.year} · $hour:$minute $meridiem';
}

String formatShortDate(DateTime value) {
  final local = value.toLocal();

  return '${_monthLabel(local.month)} ${local.day}, ${local.year}';
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
