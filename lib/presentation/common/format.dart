import '../../domain/calendar.dart';
import '../../domain/meal.dart';
import '../../domain/store_section.dart';

export '../../domain/italian_format.dart';

const mealLabels = {
  MealType.breakfast: 'Colazione',
  MealType.lunch: 'Pranzo',
  MealType.dinner: 'Cena',
};

const sectionLabels = {
  StoreSection.produce: 'Frutta e verdura',
  StoreSection.meatFish: 'Carne e pesce',
  StoreSection.dairy: 'Latticini e uova',
  StoreSection.pantry: 'Dispensa',
  StoreSection.frozen: 'Surgelati',
  StoreSection.other: 'Altro',
};

const _weekdays = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

String weekdayName(CalendarDate d) => _weekdays[d.weekday - 1];
