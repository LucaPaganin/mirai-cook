# Mirai Cook

Flutter weekly meal planner. Single user, Android first. Requirements: `docs/requirements.md` (EARS, IDs like PLAN-8).

## Stack
- Flutter, Dart (latest stable)
- State + composition root: Riverpod (with codegen)
- Persistence: Drift (SQLite)
- Backup: SQLite snapshot (`VACUUM INTO`) uploaded to Google Drive (`drive.file` scope)
- Background: `workmanager`
- Shopping list export: Google Keep via Android share intent (Keep has no public API for personal accounts)
- No backend.

## Architecture: lightweight hexagonal (ports and adapters) — mandatory
The domain is the core; everything external (DB, HTTP, Google Drive, Google Keep, Android intents, scheduler, clock) is an adapter behind a port. Dependencies point inwards only.
```
lib/
  domain/              # pure core: entities, parser, scaling, aggregation, ranking, note formatting.
                       # Imports only domain files and pure Dart (no Flutter, Riverpod, dart:io).
  application/
    ports/             # driven ports: abstract interfaces the use cases need (repositories, Clock,
                       # HttpClient, BackupTarget, LocalDatabase, ShoppingListExporter, ...).
                       # Import only domain/ and other ports.
    *.dart             # use cases (RecipeImporter, BackupService, ShoppingListExport):
                       # depend on domain + ports only. No adapters, no Flutter, no Riverpod.
    providers.dart     # composition root: the ONLY file (with main.dart/background.dart) that
                       # imports adapters and binds them to ports.
  adapters/<system>/   # driven adapters, one folder per external system: drift/, http/,
                       # google_drive/, google_keep/, android/, workmanager/, system/.
                       # Implement ports; import only domain/ + application/ports/ + own folder.
                       # Third-party/platform packages live only in their adapter folder.
  presentation/        # driving adapter (Flutter UI), feature-first. Talks to use cases and
                       # providers; never imports adapters.
test/
  domain/              # unit tests
  application/         # use cases with fakes for ports
  adapters/            # adapter tests (Drift in-memory + migration tests, ...)
  presentation/        # widget tests with ProviderScope overrides
  fixtures/            # saved HTML pages for import tests
integration_test/
```
`test/architecture_test.dart` enforces these rules (NFR-5); do not weaken it to make code fit.

### Adding an external service
1. Define the port in `lib/application/ports/` in domain terms (no SDK types in signatures).
2. Put the logic that decides *what* to do in a use case (`lib/application/`) or in `domain/`.
3. Implement the adapter in `lib/adapters/<service>/`; keep SDK/platform calls there.
   Add the package to the `restricted` map in `architecture_test.dart`.
4. Bind it in `providers.dart` (one provider per port) and add a fake in `test/fakes.dart`,
   overridden in `test/presentation/helpers.dart`.

## Commands
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test`
- `flutter test integration_test`
- `flutter analyze`

## Testing notes
- Widget tests use `appTest(...)` from `test/presentation/helpers.dart`: full app, in-memory Drift DB, fixed clock (Thu 5 Nov 2026), fakes for HTTP, share intents, Drive, the scheduler and the list exporters (`app.keep`, `app.shareSheet`).
- Seed data with `appTest(..., seed: (db) async {...})`. Multiple DB writes inside one `tester.runAsync` after the app is pumped can deadlock against Drift stream queries in the fake zone.
- Use `settle(tester)` instead of `pumpAndSettle` (a focused text field's cursor never settles).
- Host tests on Linux use the system SQLite (`hooks.user_defines.sqlite3` in `pubspec.yaml`), so they don't download native binaries from GitHub; Android builds still bundle the downloaded library.
- `test/architecture_test.dart` enforces the hexagonal layering rules and that every requirement ID has a `// Covers:` test.
