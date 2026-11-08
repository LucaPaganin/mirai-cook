import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/calendar.dart';
import '../../domain/meal.dart';
import '../../domain/recipe.dart';
import '../common/format.dart';
import 'slot_actions.dart';
import 'slot_sheet.dart';

/// Home screen: the current week, swipe for previous/next (PLAN-1, PLAN-4).
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  static const _origin = 10000;
  final _controller = PageController(initialPage: _origin);
  int _page = _origin;

  Week _weekAt(int page) {
    var w = ref.read(currentWeekProvider);
    final offset = page - _origin;
    for (var i = 0; i < offset.abs(); i++) {
      w = offset > 0 ? w.next : w.previous;
    }
    return w;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentWeekProvider);
    final week = _weekAt(_page);
    return Scaffold(
      appBar: AppBar(
        title: Text(weekRange(week)),
        actions: [
          if (_page != _origin)
            IconButton(
              tooltip: 'Settimana corrente',
              icon: const Icon(Icons.today),
              onPressed: () => _controller.animateToPage(
                _origin,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (_) => duplicatePreviousWeek(context, ref, week),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'dup',
                child: Text('Duplica settimana precedente'),
              ),
            ],
          ),
        ],
      ),
      body: PageView.builder(
        key: const Key('week-pager'),
        controller: _controller,
        onPageChanged: (p) => setState(() => _page = p),
        itemBuilder: (context, page) => WeekView(week: _weekAt(page)),
      ),
    );
  }
}

class WeekView extends ConsumerWidget {
  const WeekView({super.key, required this.week});

  final Week week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(weekPlanProvider(week)).value ?? const {};
    final recipes = ref.watch(recipeIndexProvider).value ?? const {};
    final defaultServings = ref.watch(defaultServingsProvider).value ?? 1;
    final today = ref.watch(todayProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final day in week.days)
          _DayCard(
            day: day,
            isToday: day == today,
            plan: plan,
            recipes: recipes,
            defaultServings: defaultServings,
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.plan,
    required this.recipes,
    required this.defaultServings,
  });

  final CalendarDate day;
  final bool isToday;
  final Map<SlotId, List<SlotItem>> plan;
  final Map<int, RecipeSummary> recipes;
  final double defaultServings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      shape: isToday
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '${weekdayName(day)} ${shortDate(day)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final meal in MealType.values)
              SlotTile(
                slot: SlotId(day, meal),
                items: plan[SlotId(day, meal)] ?? const [],
                recipes: recipes,
                defaultServings: defaultServings,
              ),
          ],
        ),
      ),
    );
  }
}

class SlotTile extends ConsumerWidget {
  const SlotTile({
    super.key,
    required this.slot,
    required this.items,
    required this.recipes,
    required this.defaultServings,
  });

  final SlotId slot;
  final List<SlotItem> items;
  final Map<int, RecipeSummary> recipes;
  final double defaultServings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key('slot-${slot.date.toInt()}-${slot.meal.name}'),
      onTap: () => showSlotSheet(context, slot),
      onLongPress: items.isEmpty
          ? null
          : () => showSlotActions(context, ref, slot),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                mealLabels[slot.meal]!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Text(
                      '—',
                      style: TextStyle(color: theme.colorScheme.outline),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in items)
                          Text(slotItemLabel(item, recipes, defaultServings)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text for a slot item; shows "×N" when servings differ from the default
/// (PLAN-17).
String slotItemLabel(
  SlotItem item,
  Map<int, RecipeSummary> recipes,
  double defaultServings,
) => switch (item) {
  FreeTextItem(:final text) => text,
  RecipeItem(:final recipeId, :final servings) =>
    (recipes[recipeId]?.title ?? '…') +
        (servings != defaultServings ? ' ×${formatNumber(servings)}' : ''),
};
