abstract final class DateFormatter {
  static String formatDate(DateTime dt) =>
      '${dt.year}.${_pad(dt.month)}.${_pad(dt.day)}';

  static String formatDateTime(DateTime dt) =>
      '${formatDate(dt)} ${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String formatTime(DateTime dt) =>
      '${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
