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

## Current mobile scope
Native Flutter shell; sign-in and account creation; shared Supabase email/password identity and persisted session; Home, Learn, Campus, Community and Profile tabs; shared messages and notifications; native course, community, marketplace and selected admin workflows. The full website Admin Portal is opened inside an authenticated in-app WebView for role-authorized admin/super-admin users so the existing complete control board remains available while native admin parity is built. The WebView receives only the signed-in user's Supabase session; no service-role key is placed in the app.

The app and website share the same Supabase project and user identity. This does not mean every website feature has a native Flutter implementation yet. Native feature parity will be delivered in tested vertical slices. No production database schema or RLS changes are made by the mobile client.
