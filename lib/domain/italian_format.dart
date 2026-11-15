/// Italian formatting of numbers, amounts and dates, shared by the UI and
/// by exports (EXP-1).
library;

import 'calendar.dart';
import 'units.dart';

String formatNumber(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

const _plurals = <String, String>{
  'cucchiaio': 'cucchiai',
  'cucchiaino': 'cucchiaini',
  'spicchio': 'spicchi',
  'foglia': 'foglie',
  'rametto': 'rametti',
  'ciuffo': 'ciuffi',
  'mazzetto': 'mazzetti',
  'bustina': 'bustine',
  'cubetto': 'cubetti',
  'fetta': 'fette',
  'pezzo': 'pezzi',
  'vasetto': 'vasetti',
  'barattolo': 'barattoli',
  'scatola': 'scatole',
  'confezione': 'confezioni',
  'lattina': 'lattine',
  'bicchiere': 'bicchieri',
  'tazza': 'tazze',
  'tazzina': 'tazzine',
  'gambo': 'gambi',
  'costa': 'coste',
  'filetto': 'filetti',
};

String formatAmount(Amount a) {
  final n = formatNumber(a.value);
  final unit = a.unit;
  if (unit == null) return n;
  final label = a.value > 1 ? (_plurals[unit] ?? unit) : unit;
  return '$n $label';
}

const _months = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String shortDate(CalendarDate d) => '${d.day} ${_months[d.month - 1]}';

String weekRange(Week w) => '${shortDate(w.monday)} – ${shortDate(w.sunday)}';
