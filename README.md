# Meal Reservation (Flutter)

Meal reservation app for events, built with Flutter. This was ported from
an original native Android app; the two restaurateur screens that were
UI-only stubs in that original (catalog management, product form, schedule
management) are kept as the same non-functional stubs, for fidelity.
Everything is local-only (no backend): applicant login/signup, date &
service selection, product catalogue, basket, reservation confirmation, and
the restaurateur side (login, dashboard, orders list/detail/history).

Flutter isn't installed in the environment this was written in, so this
repo only contains `pubspec.yaml` + `lib/` (pure Dart, no platform
folders). To run it:

```bash
flutter create .          # generates android/, ios/, etc. without touching lib/ or pubspec.yaml
flutter pub get
flutter run                # or: flutter build apk
```

## Structure

- `lib/data/local_store.dart` - port of `MealReservationLocalStore.kt`, backed by `shared_preferences` (JSON-encoded, same keys/shape as the Android SharedPreferences store).
- `lib/screens/` - one file per original Activity.
- `lib/widgets/common.dart` - shared styled widgets (buttons, fields, cards) matching the original color scheme (`prussian_blue` / `amber_honey` / etc., ported to `lib/theme/app_colors.dart`).

## Known gaps / deviations

- The original app's launcher icon wasn't carried over (the Android project has been removed from this repo) - `flutter create` will generate default Flutter icons; drop a replacement into `android/app/src/main/res` / `ios/Runner/Assets.xcassets` if needed.
- The Android `DatePicker` (always-visible spinner) is replaced by a tappable field opening `showDatePicker` - functionally equivalent, more idiomatic on Flutter.
- Since this is Flutter, the app now also runs on iOS/web/desktop, not just Android (nothing Android-specific was used).
