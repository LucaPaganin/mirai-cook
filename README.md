# Mirai Cook

Weekly meal planner for Android (Flutter). Requirements: [`docs/requirements.md`](docs/requirements.md).

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Generated files (`*.g.dart`) are committed; regenerate them after changing
Drift tables or Riverpod providers.

### Schema changes

1. Change the tables in `lib/data/db/tables.dart` and bump `schemaVersion`.
2. Add the migration step in `AppDatabase.migration`.
3. `dart run drift_dev make-migrations` — exports `drift_schemas/` and
   generates step-by-step migration tests under `test/data/generated_migrations/`.

## Google Drive backup setup

Backups use Google Sign-In with the `drive.file` scope. Before the
"Collega Google Drive" button works on a device you need a Google Cloud
project:

1. Create a project at <https://console.cloud.google.com/> and enable the
   **Google Drive API**.
2. Configure the OAuth consent screen (External, add yourself as test user,
   scope `.../auth/drive.file`).
3. Create an **Android** OAuth client with package name
   `com.lucapaganin.mirai_cook` and the SHA-1 of your signing key
   (`cd android && ./gradlew signingReport`).
4. Create a **Web application** OAuth client and pass its client ID at build
   time:

   ```sh
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
   ```

Snapshots go to a visible Drive folder named **Mirai Cook backup**.

## Sharing recipes into the app

Use Android's *Share* from a browser or recipe app and choose Mirai Cook; the
first URL in the shared text is imported. You can also paste a URL from the
link icon in the recipe book.
