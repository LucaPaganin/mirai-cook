# Mirai Cook — MVP Requirements (EARS)

Weekly meal planning app. Single user, Android first (Flutter, so iOS later is possible).
Primary quality goal: **planning a week must be fast**.

EARS patterns used:
- Ubiquitous: *The app shall …*
- Event-driven: *When <trigger>, the app shall …*
- State-driven: *While <state>, the app shall …*
- Unwanted behaviour: *If <condition>, then the app shall …*
- Optional feature: *Where <feature>, the app shall …*

---

## 1. Weekly plan (PLAN)

- **PLAN-1** The app shall show the current week (Monday to Sunday) as its home screen, as a vertical list of days, each containing its meal slots.
- **PLAN-2** The app shall provide three fixed meal slots per day: breakfast, lunch, dinner.
- **PLAN-3** The app shall allow a slot to contain an ordered list of zero or more items, each being either free text or a reference to a recipe.
- **PLAN-4** When the user swipes horizontally on the week view, the app shall show the previous or next week.
- **PLAN-5** When the user taps a slot, the app shall open a bottom sheet listing the slot's existing items and a text field to add a new item, focused with the keyboard open.
- **PLAN-6** When the user types in the slot field, the app shall suggest matching recipes and previously used free texts, ranked by frequency and recency of use.
- **PLAN-7** When the user selects a suggestion or confirms the typed text, the app shall add it as an item to the slot, save the slot and close the bottom sheet.
- **PLAN-8** The app shall allow assigning a meal to an empty slot with at most 2 taps plus typing.
- **PLAN-9** When the user long-presses a slot, the app shall offer to move or copy it (all its items) to another slot.
- **PLAN-10** When the user requests "duplicate previous week" on a week, the app shall copy all slots of the previous week, with all their items, into that week.
- **PLAN-11** If the target week already contains non-empty slots when duplicating, then the app shall ask for confirmation before overwriting them.
- **PLAN-12** Where a slot item references a recipe, the app shall allow setting the number of servings for that item, defaulting to the "default servings" setting (default 1).
- **PLAN-13** The app shall determine "current week" from an injected clock, never directly from the system time.
- **PLAN-14** The app shall treat Monday as the first day of the week; this is not configurable in the MVP.
- **PLAN-15** The app shall identify a slot by its calendar date and meal type, not by week number and day index.
- **PLAN-16** When the user swipes a slot item in the bottom sheet, the app shall remove that item.
- **PLAN-17** Where a recipe item's servings differ from the default servings, the app shall show the servings on the slot (e.g. "×4").
- **PLAN-18** The app shall provide a "default servings" setting, default 1.

## 2. Recipe book (RCP)

- **RCP-1** The app shall provide a recipe book listing all saved recipes, searchable by title.
- **RCP-2** The app shall store for each recipe: title, servings, ingredient lines, steps, optional source URL, optional thumbnail.
- **RCP-3** The app shall store each ingredient as its original text line, plus optional parsed fields (quantity, unit, name).
- **RCP-4** The app shall always display the original ingredient line to the user.
- **RCP-5** The app shall allow creating, editing and deleting recipes manually.
- **RCP-6** If a recipe referenced by slot items is deleted, then the app shall convert those items to free text with the recipe title.

## 3. Recipe import from URL (IMP)

- **IMP-1** When the user shares a URL to the app from another Android app, the app shall start a recipe import from that URL.
- **IMP-2** The app shall also allow starting an import by pasting a URL.
- **IMP-3** When importing, the app shall extract title, servings, ingredients, steps and image from schema.org `Recipe` JSON-LD in the page.
- **IMP-4** When importing ingredients, the app shall store each as an original line and run the ingredient parser on it.
- **IMP-5** If the page has no valid `Recipe` JSON-LD, then the app shall open the unsaved recipe editor prefilled with only the page title and source URL.
- **IMP-6** If the page cannot be fetched, then the app shall show an error offering "Retry" and "Continue manually" (unsaved editor prefilled with the source URL).
- **IMP-7** When an image is available, the app shall store a compressed thumbnail (target ≤ 50 KB) inside the database.
- **IMP-8** The app shall show every import in the recipe editor, prefilled and unsaved; the recipe shall be persisted only when the user taps "Save", and discarded on "Cancel".
- **IMP-9** If a recipe with the same source URL already exists, then the app shall tell the user and offer to open the existing recipe instead of importing a duplicate.

## 4. Shopping list (SHOP)

- **SHOP-1** The app shall keep one shopping list per week, containing the ingredients of all recipes referenced by that week's slot items.
- **SHOP-2** The app shall scale ingredient quantities by item servings / recipe servings.
- **SHOP-3** The app shall merge ingredients only when their normalized names are identical and their units are identical or convertible within the same dimension; otherwise it shall keep them as separate lines.
- **SHOP-4** If an ingredient has no parsed quantity, then the app shall list its original line without merging.
- **SHOP-5** The app shall allow adding and removing manual items.
- **SHOP-6** The app shall allow checking and unchecking items, persisting their state.
- **SHOP-7** When the week's plan changes, the app shall recompute the recipe-derived items automatically, preserving manual items and the checked state of items that still exist.
- **SHOP-8** If the quantity of a checked item increases after recomputation, then the app shall uncheck it.
- **SHOP-9** Free-text slot items shall never contribute to the shopping list.
- **SHOP-10** The app shall convert units within the same dimension using a fixed table: mass (g, kg) and volume (ml, cl, dl, l, cucchiaio, cucchiaino); merged quantities shall be shown in the most readable unit (e.g. 1,2 kg). Other units (spicchio, pizzico, …) shall not be converted.
- **SHOP-11** The app shall normalize ingredient names mechanically: lowercase, trimmed, collapsed whitespace, accent normalization. No singular/plural heuristics.
- **SHOP-12** When the user merges two shopping list items ("merge with…"), the app shall store a persistent alias between their normalized names and apply it to future aggregations. Original ingredient lines shall remain unchanged.
- **SHOP-13** The app shall group shopping list items by store section (Frutta e verdura, Carne e pesce, Latticini, Dispensa, Surgelati, Altro), sorted alphabetically within a section, with checked items at the bottom.
- **SHOP-14** The app shall assign sections by normalized name from a seeded table of common ingredients; unknown names go to "Altro".
- **SHOP-15** When the user changes an item's section, the app shall remember it for that normalized name.

## 5. Persistence and backup (DATA)

- **DATA-1** The app shall store all data in a local SQLite database (Drift).
- **DATA-2** The app shall work fully offline, except URL import and backup upload.
- **DATA-3** When the app goes to background and data changed since the last backup, the app shall create a backup.
- **DATA-4** The app shall also attempt a backup at least once per day via a background task.
- **DATA-5** When creating a backup, the app shall produce a consistent snapshot with `VACUUM INTO` and never copy the live database file.
- **DATA-6** The app shall upload snapshots to a visible Google Drive folder using the `drive.file` scope.
- **DATA-7** The app shall keep the last N snapshots on Drive (N configurable, default 10) and delete older ones.
- **DATA-8** When the user restores a snapshot, the app shall replace the local database only after validating it.
- **DATA-9** If a snapshot has an older schema version, then the app shall migrate it to the current version on restore.
- **DATA-10** If a snapshot has a newer schema version than the app, then the app shall refuse the restore and explain why.
- **DATA-11** If a backup upload fails, then the app shall retry at the next trigger and show the last successful backup time in settings.
- **DATA-12** The app shall keep backup disabled until the user connects a Google account in settings; all other features shall work without it.
- **DATA-13** While backup is not configured, the app shall show a non-blocking warning in settings (and a badge) that data exists only on the device.
- **DATA-14** When the app starts with an empty database, the app shall offer "Restore from Google Drive" or "Start fresh".
- **DATA-15** When restoring, the app shall list available snapshots with date/time and recipe count.
- **DATA-16** Before replacing the database on restore, the app shall create a local snapshot of the current database so the restore can be undone.
- **DATA-17** When the user disconnects the Google account, the app shall leave existing snapshots on Drive.

## 6. Non-functional (NFR)

- **NFR-1** Domain logic (ingredient parsing, quantity scaling, list aggregation, suggestion ranking) shall be pure Dart with no Flutter or Riverpod dependency.
- **NFR-2** All external dependencies (database, HTTP, Google Drive, clock, background scheduler) shall be injected behind interfaces.
- **NFR-3** Tests shall not perform network calls or depend on system time.
- **NFR-4** Every requirement ID shall be referenced by at least one test (`// Covers: PLAN-8`).

## 7. Ingredient parser (PARSE)

- **PARSE-1** The parser shall support Italian ingredient lines only in the MVP.
- **PARSE-2** The parser shall recognise integers and decimals with comma or dot (`200`, `1,5`, `0.5`).
- **PARSE-3** The parser shall recognise fractions (`1/2`, `½`, `1 ½`).
- **PARSE-4** The parser shall recognise ranges (`2-3 uova`) and store the maximum value.
- **PARSE-5** The parser shall recognise the unit before or after the quantity, with or without a space (`g 200 farina`, `200 g di farina`, `200g farina`), stripping the "di"/"d'" connector from the name.
- **PARSE-6** The parser shall treat "q.b.", "un pizzico", "a piacere" and any unrecognised line as having no quantity.

---

## Out of scope for MVP
Multi-user sync, iOS release, LLM-based import, automatic meal plan generation, nutrition tracking, JSON export,
configurable first day of week, configurable/extra meal slots, shopping list over arbitrary date ranges,
cross-dimension unit conversion (cups, densities), English/imperial ingredient parsing, custom/reorderable store sections.

## Data model notes
- Slot items: `slot_item(date, meal_type, position, free_text | recipe_id, servings)`.
- Shopping list persisted state: manual items and checked flags keyed by (normalized name, unit dimension); recipe-derived items are computed.
- Tables for `ingredient_alias` and `ingredient_section`.

## Open points
- Suggestion ranking formula (PLAN-6): weighting of frequency vs. recency to be fixed during implementation.
