abstract final class CurrencyFormatter {
  static String format(int amount) {
    final buf = StringBuffer();
    final str = amount.abs().toString();
    final mod = str.length % 3;

    for (var i = 0; i < str.length; i++) {
      if (i != 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }

    return '${amount < 0 ? '-' : ''}${buf.toString()}원';
  }
}
