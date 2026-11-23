# Playbook: App (mobile and desktop)

## When it applies
Android and iOS apps, and desktop apps for Windows, macOS or Linux. An app with a backend also uses `web.md` for the API.

## Stack options to research
- Cross-platform mobile: React Native with Expo, Flutter.
- Native: Kotlin + Jetpack Compose (Android), Swift + SwiftUI (iOS/macOS).
- Desktop: Tauri (small, Rust core), Electron (large, mature), Flutter desktop.
- Web-first alternative: a PWA, when store presence is not required.
- Backend and auth: Supabase, Firebase, or your own API.

## Test tools
- Unit: Jest/Vitest (RN, Electron, Tauri front end), `flutter test`, JUnit (Android), XCTest (iOS).
- UI / end-to-end: Maestro or Detox (mobile), Playwright (Electron/Tauri web views).
- Real-device or emulator screenshot as proof for UI changes.

## Required project commands
Record in `AGENTS.md`: install, dev (emulator or desktop window), test, lint, typecheck, build (per platform), release build / sign, store upload (e.g. EAS Submit, Fastlane).

## Security basics (OWASP MASVS)
- Store tokens in secure storage (Keychain, Android Keystore, OS credential store), never plain prefs or files.
- No API secrets in the app binary; anything shipped can be extracted. Use your backend.
- HTTPS only; no disabled certificate checks.
- Validate deep links and intents; do not run actions from untrusted links without confirmation.
- Desktop (Electron): `contextIsolation` on, `nodeIntegration` off, a strict CSP, no remote content with Node access.
- Ask for the fewest permissions, at the moment they are needed.

## Standards
- OWASP MASVS (mobile app security verification standard).
- Google Play policies, including the current target API level requirement (it rises each year; check before release).
- Apple App Store Review Guidelines; privacy manifest and privacy "nutrition label" for iOS.
- macOS apps outside the App Store must be signed and notarized. Windows apps should be code-signed to avoid SmartScreen warnings.
- Material Design (Android) and Apple Human Interface Guidelines for platform feel; WCAG 2.2 AA principles for accessibility.

## Before-publish checklist
- [ ] Tests, lint, typecheck pass; release build succeeds for each platform (paste output).
- [ ] App signed with the release key; signing keys backed up and not in the repo.
- [ ] Android: targets the currently required API level. New personal Play developer accounts must run a closed test (check the current tester count and days in Play Console) before production.
- [ ] iOS: privacy manifest and App Privacy answers match what the app collects; TestFlight build tested.
- [ ] macOS: notarized. Windows: installer signed.
- [ ] Permissions requested only when used, with a clear reason string.
- [ ] Tested on a small phone, a large phone, and (if supported) a tablet; dark mode checked.
- [ ] Crash reporting on; no personal data in logs.
- [ ] Store listing: icon, screenshots per device size, description, privacy policy URL, support contact.
- [ ] Version and build numbers bumped.

## Sources
- OWASP MASVS: https://mas.owasp.org/MASVS/
- Google Play target API requirement: https://developer.android.com/google/play/requirements/target-sdk
- Play testing requirements for new personal accounts: https://support.google.com/googleplay/android-developer/answer/14151465
- Apple App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- macOS notarization: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- Electron security: https://www.electronjs.org/docs/latest/tutorial/security
