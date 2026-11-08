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

## CI and releases

`.github/workflows/android.yml` runs on every push:

1. **Analyze & test**: checks generated code is committed, `flutter analyze`, `flutter test`.
2. **Build APK**: release APK uploaded as the `mirai-cook-apk` artifact
   (Actions → run → Artifacts).

3. **Automatic release** on every push to `main` (e.g. a merged PR): the
   version is the latest `vX.Y.Z` tag with the patch bumped (`0.1.0` →
   `0.1.1`); the tag and GitHub release with the APK are created by the
   workflow. Tags created this way don't trigger further workflow runs.

To jump to a specific version (e.g. `0.2.0`), run `.github/workflows/release.yml`
by hand: **Actions → Release → Run workflow**, pick `main` and enter the
version. Following automatic releases continue from there (`0.2.1`, …).

The Android version code is the commit count, so every new build on `main`
installs over the previous one (given the same signing key).

### Signing key (recommended)

Without a key, CI signs with a throwaway debug key that changes on every
run: each new APK then requires uninstalling the old one, and Google Sign-In
won't work (its SHA-1 changes). Create a key once:

```sh
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
base64 -w0 upload-keystore.jks   # value for ANDROID_KEYSTORE_BASE64
keytool -list -v -keystore upload-keystore.jks -alias upload  # SHA-1 for Google Cloud
```

Repository settings → Secrets and variables → Actions:

| Kind | Name |
|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` |
| Variable | `GOOGLE_SERVER_CLIENT_ID` (web OAuth client ID, see below) |

Keep the `.jks` file safe outside the repo: losing it means users must
reinstall.

For local release builds, create `android/key.properties` (gitignored) with
`storeFile`, `storePassword`, `keyAlias`, `keyPassword`.

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
