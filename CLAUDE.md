# Mirai Cook

Flutter weekly meal planner. Single user, Android first. Requirements: `docs/requirements.md` (EARS, IDs like PLAN-8).

## Stack
- Flutter, Dart (latest stable)
- State + composition root: Riverpod (with codegen)
- Persistence: Drift (SQLite)
- Backup: SQLite snapshot (`VACUUM INTO`) uploaded to Google Drive (`drive.file` scope)
- Background: `workmanager`
- No backend.

## Architecture
```
lib/
  domain/        # pure Dart: entities, parser, scaling, aggregation, ranking. No Flutter, no Riverpod.
  data/          # repository interfaces + Drift/HTTP/Drive implementations
  application/   # Riverpod providers wiring everything (composition root)
  presentation/  # screens and widgets, feature-first
test/
  domain/        # unit tests
  data/          # Drift in-memory + migration tests
  presentation/  # widget tests with ProviderScope overrides
  fixtures/      # saved HTML pages for import tests
integration_test/
```

## Rules
- Domain classes receive dependencies via constructor. Never import Riverpod in `domain/`.
- Every external dependency sits behind an interface: `Clock`, `HttpClient`, `BackupTarget`, `BackgroundScheduler`, repositories.
- Never call `DateTime.now()` outside the `SystemClock` implementation.
- Tests: no network, no real time. Use `NativeDatabase.memory()`, fakes over mocks where practical, `ProviderScope(overrides: ...)` in widget tests.
- Each test references the requirement it covers: `// Covers: SHOP-3`.
- Write the test first for domain logic; prefer parametrized cases for the ingredient parser.
- Schema changes: bump `schemaVersion`, add a migration step, export the schema, add a migration test.

## Commands
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test`
- `flutter test integration_test`
- `flutter analyze`

## Testing notes
- Widget tests use `appTest(...)` from `test/presentation/helpers.dart`: full app, in-memory Drift DB, fixed clock (Thu 5 Nov 2026), fakes for HTTP, share intents, Drive and the scheduler.
- Seed data with `appTest(..., seed: (db) async {...})`. Multiple DB writes inside one `tester.runAsync` after the app is pumped can deadlock against Drift stream queries in the fake zone.
- Use `settle(tester)` instead of `pumpAndSettle` (a focused text field's cursor never settles).
- Host tests on Linux use the system SQLite (`hooks.user_defines.sqlite3` in `pubspec.yaml`), so they don't download native binaries from GitHub; Android builds still bundle the downloaded library.
- `test/architecture_test.dart` enforces the layering rules and that every requirement ID has a `// Covers:` test.
