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

- **PLAN-1** The app shall show the current week as its home screen, as a vertical list of days, each containing its meal slots.
- **PLAN-2** The app shall provide two meal slots per day (lunch, dinner) by default.
- **PLAN-3** The app shall allow a slot to contain either free text or a reference to a recipe, or to be empty.
- **PLAN-4** When the user swipes horizontally on the week view, the app shall show the previous or next week.
- **PLAN-5** When the user taps a slot, the app shall open a bottom sheet with a single text field focused and the keyboard open.
- **PLAN-6** When the user types in the slot field, the app shall suggest matching recipes and previously used free texts, ranked by frequency and recency of use.
- **PLAN-7** When the user selects a suggestion or confirms the typed text, the app shall save the slot and close the bottom sheet.
- **PLAN-8** The app shall allow assigning a meal to an empty slot with at most 2 taps plus typing.
- **PLAN-9** When the user long-presses a slot, the app shall offer to move or copy it to another slot.
- **PLAN-10** When the user requests "duplicate previous week" on a week, the app shall copy all slots of the previous week into that week.
- **PLAN-11** If the target week already contains non-empty slots when duplicating, then the app shall ask for confirmation before overwriting them.
- **PLAN-12** Where a slot references a recipe, the app shall allow setting the number of servings for that slot, defaulting to the recipe's servings.
- **PLAN-13** The app shall determine "current week" from an injected clock, never directly from the system time.

## 2. Recipe book (RCP)

- **RCP-1** The app shall provide a recipe book listing all saved recipes, searchable by title.
- **RCP-2** The app shall store for each recipe: title, servings, ingredient lines, steps, optional source URL, optional thumbnail.
- **RCP-3** The app shall store each ingredient as its original text line, plus optional parsed fields (quantity, unit, name).
- **RCP-4** The app shall always display the original ingredient line to the user.
- **RCP-5** The app shall allow creating, editing and deleting recipes manually.
- **RCP-6** If a recipe referenced by plan slots is deleted, then the app shall convert those slots to free text with the recipe title.

## 3. Recipe import from URL (IMP)

- **IMP-1** When the user shares a URL to the app from another Android app, the app shall start a recipe import from that URL.
- **IMP-2** The app shall also allow starting an import by pasting a URL.
- **IMP-3** When importing, the app shall extract title, servings, ingredients, steps and image from schema.org `Recipe` JSON-LD in the page.
- **IMP-4** When importing ingredients, the app shall store each as an original line and run the ingredient parser on it.
- **IMP-5** If the page has no valid `Recipe` JSON-LD, then the app shall save a recipe with the page title and source URL and open it in the editor.
- **IMP-6** If the page cannot be fetched, then the app shall show an error and keep the URL available for retry.
- **IMP-7** When an image is available, the app shall store a compressed thumbnail (target ≤ 50 KB) inside the database.
- **IMP-8** The app shall show the imported recipe for review before it is saved.

## 4. Shopping list (SHOP)

- **SHOP-1** When the user generates the shopping list for a week, the app shall collect the ingredients of all recipes referenced in that week's slots.
- **SHOP-2** The app shall scale ingredient quantities by slot servings / recipe servings.
- **SHOP-3** The app shall merge ingredients only when normalized name and unit are identical; otherwise it shall keep them as separate lines.
- **SHOP-4** If an ingredient has no parsed quantity, then the app shall list its original line without merging.
- **SHOP-5** The app shall allow adding and removing manual items.
- **SHOP-6** The app shall allow checking and unchecking items, persisting their state.
- **SHOP-7** If the list is regenerated, then the app shall preserve manual items and the checked state of items that still exist.

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

## 6. Non-functional (NFR)

- **NFR-1** Domain logic (ingredient parsing, quantity scaling, list aggregation, suggestion ranking) shall be pure Dart with no Flutter or Riverpod dependency.
- **NFR-2** All external dependencies (database, HTTP, Google Drive, clock, background scheduler) shall be injected behind interfaces.
- **NFR-3** Tests shall not perform network calls or depend on system time.
- **NFR-4** Every requirement ID shall be referenced by at least one test (`// Covers: PLAN-8`).

---

## Out of scope for MVP
Multi-user sync, iOS release, LLM-based import, automatic meal plan generation, nutrition tracking, JSON export.

## Open points
- First day of week (Monday assumed).
- Configurable meal slots beyond lunch/dinner (e.g. breakfast)?
- Shopping list units normalization (g/kg, ml/l): convert or not?
