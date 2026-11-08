import 'calendar.dart';

/// Fixed meal slots, in display order (PLAN-2).
enum MealType { breakfast, lunch, dinner }

/// Identifies a slot by calendar date and meal type (PLAN-15).
class SlotId {
  const SlotId(this.date, this.meal);

  final CalendarDate date;
  final MealType meal;

  @override
  bool operator ==(Object other) =>
      other is SlotId && other.date == date && other.meal == meal;

  @override
  int get hashCode => Object.hash(date, meal);

  @override
  String toString() => 'SlotId($date, ${meal.name})';
}

/// One entry of a slot: free text or a recipe reference (PLAN-3).
sealed class SlotItem {
  const SlotItem();
}

class FreeTextItem extends SlotItem {
  const FreeTextItem(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is FreeTextItem && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class RecipeItem extends SlotItem {
  const RecipeItem({required this.recipeId, required this.servings});

  final int recipeId;
  final double servings;

  @override
  bool operator ==(Object other) =>
      other is RecipeItem &&
      other.recipeId == recipeId &&
      other.servings == servings;

  @override
  int get hashCode => Object.hash(recipeId, servings);
}

class Slot {
  const Slot(this.id, this.items);

  final SlotId id;
  final List<SlotItem> items;

  bool get isEmpty => items.isEmpty;
}
