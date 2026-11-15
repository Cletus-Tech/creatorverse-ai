# CreatorVerse Mobile

Flutter client for CreatorVerse. Android is the first build target; iOS compatibility is retained.

## Build APK
\`\`\`bash
flutter create --platforms=android --org com.cletustech --project-name creatorverse_mobile .
flutter pub get
flutter analyze
flutter test
flutter build apk --release
\`\`\`
APK: \`build/app/outputs/flutter-apk/app-release.apk\`. GitHub Actions uploads the APK as the **creatorverse-android-release** artifact.

The app uses the same Supabase project as the website. Configure \`SUPABASE_URL\` and \`SUPABASE_PUBLISHABLE_KEY\` with Dart compile-time defines. Defaults match the website's public client configuration. Never put a service-role or secret key in a mobile app.

## First build scope
Native Flutter shell; sign-in and account creation; shared Supabase email/password identity and persisted session; Home, Learn, Campus, Community and Profile tabs. Existing modules, messages and notifications open their current website routes. No production database schema or RLS changes are made.

This is an installable first mobile preview, not a claim of full native feature parity. Native features will be implemented in tested vertical slices.
