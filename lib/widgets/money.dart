import 'package:intl/intl.dart';

String money(num value) => NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
).format(value);
String dateLabel(DateTime date) =>
    DateFormat("d 'de' MMM", 'es_CO').format(date);
