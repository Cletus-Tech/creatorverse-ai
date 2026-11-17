# CreatorVerse Android OTA setup

CreatorVerse uses Shorebird Code Push for Flutter/Dart-only updates. The normal Android release remains the route for changes to Kotlin/Java, Android permissions, Gradle/build configuration, native plugin code, Flutter engine versions, images, fonts, and other bundled assets.

## One-time account and project setup

1. Create a Shorebird account at https://console.shorebird.dev.
2. In the Shorebird Console, open **Account → API Keys**, create an API key with permission to create/manage apps and releases, and copy it. In GitHub, open **Cletus-Tech/creatorverse-ai → Settings → Secrets and variables → Actions**, then create this repository secret:

   - `SHOREBIRD_TOKEN` — the Shorebird API key.

   Never commit or share this token. You do not need to send it to ChatGPT.

3. In GitHub, open **Actions → Initialize CreatorVerse Shorebird App → Run workflow**. If your Shorebird account belongs to more than one organization, enter the organization ID; otherwise leave it blank. The workflow creates the Shorebird app, generates `apps/mobile/shorebird.yaml`, adds it to the Flutter asset list, and commits those configuration changes to the existing `main` branch.

   The generated `app_id` is public configuration and is safe to keep in GitHub. The API token remains in GitHub Actions secrets.

   You can do the same setup locally instead, if preferred: install the Shorebird CLI, run `shorebird login`, then `shorebird init --display-name "CreatorVerse"` from `apps/mobile`.

## One-time Android signing setup

A persistent signing key is required so future full Android releases can update the installed app instead of forcing an uninstall/reinstall. Generate it locally and keep a secure backup. Do not commit the keystore.

In PowerShell, run:

```powershell
keytool -genkeypair -v -keystore creatorverse-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias creatorverse-upload
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\creatorverse-upload.jks")) | Set-Clipboard
```

In the same GitHub Actions secrets page, add:

- `ANDROID_KEYSTORE_BASE64` — paste the Base64 value copied to the clipboard.
- `ANDROID_KEYSTORE_PASSWORD` — the keystore password you chose.
- `ANDROID_KEY_ALIAS` — `creatorverse-upload`.
- `ANDROID_KEY_PASSWORD` — the key password you chose.

Keep the original `creatorverse-upload.jks` and its passwords backed up somewhere private and secure. Losing the signing key can prevent future direct Android releases from updating existing installations.

## Enable automatic Dart patches

In GitHub, open **Settings → Secrets and variables → Actions → Variables** and create:

- `SHOREBIRD_ENABLED` = `true`

The workflow intentionally skips automatic OTA jobs until this variable is enabled. This avoids failed patch runs before the Shorebird app, token, and baseline release are ready.

## Create the first Shorebird-enabled release

1. Confirm `apps/mobile/shorebird.yaml` is committed to `main`.
2. Confirm all five GitHub Actions secrets are present.
3. Open **Actions → CreatorVerse Android — Shorebird OTA and Releases → Run workflow**.
4. Choose operation **release** and run it.
5. When the workflow succeeds, download the `creatorverse-android-shorebird-release` artifact and install its APK.

This is the one required transition from the previous non-Shorebird APK to a Shorebird-enabled installation. If Android refuses to update the old APK because it was signed with a different key, uninstall the old app once and install this baseline. CreatorVerse account data, messages, courses, and other server-side records remain in Supabase; you may need to sign in again.

The first Shorebird release is version `1.0.1+2`. Keep the same signing key for all later full Android releases.

## How updates work after the baseline

- A commit that changes Dart files under `apps/mobile/lib/` on `main` automatically runs a Shorebird patch on the `stable` track when `SHOREBIRD_ENABLED=true`.
- The app checks for the patch at startup, downloads it in the background, and applies it on the next app launch.
- No APK download or manual installation is needed for a successful Dart-only patch.
- For a native Android/plugin/permission/build/asset/Flutter-version change, increment the app version in `pubspec.yaml`, then manually run the same workflow with operation **release**. That produces a new signed APK (and App Bundle) for distribution through Google Play or, while testing, manual installation.
- Never bypass Shorebird's native-code or asset-difference warnings just to force a patch. A patch cannot deliver those files and can break the app.

## Current release version

The repository is prepared for the first Shorebird release at `1.0.1+2`. OTA is not active on installed phones until the app ID is committed, GitHub secrets and variable are configured, and the first Shorebird-enabled release is installed.
