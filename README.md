# Meal Reservation (Flutter + Firebase)

Meal reservation app for events. Two apps share one codebase and one
Firebase project, so what one side does shows up on the other in real time:

- **Client app** (`lib/main.dart`, flavor `client`): members sign up / log in,
  see the dates opened by the restaurateur, order from the catalogue, and
  follow the status of their orders.
- **Admin app** (`lib/main_admin.dart`, flavor `admin`): the restaurateur
  manages the catalogue (products grouped into family tabs), opens
  dates/services, and processes incoming orders.

Data lives in Cloud Firestore (project `meal-reservation-tennis`,
region `europe-west3`), accounts in Firebase Authentication.

## One-time Firebase setup

1. **Enable Authentication**: Firebase console → Authentication → *Get started*
   → *Sign-in method* → enable **Email/Password**.
2. **Create the restaurateur account**:
   - Authentication → *Users* → *Add user* (email + password of your choice), and copy its **User UID**.
   - Firestore Database → *Start collection* `admins` → document ID = that UID
     (add any field, e.g. `role: "admin"`).

   Only accounts listed in `admins` can log into the admin app. Client
   accounts are created from the client app's signup screen.

The security rules are in `firestore.rules` (already deployed). After
editing them, redeploy with `firebase deploy --only firestore:rules`
(needs the Firebase CLI) or from the console's *Rules* tab.

## Running

Firebase does not support Linux desktop, so test on an Android device /
emulator or in Chromium:

```bash
export CHROME_EXECUTABLE=/snap/bin/chromium
flutter run -d chrome                          # client app
flutter run -d chrome -t lib/main_admin.dart   # admin app
```

On Android (both apps can be installed side by side):

```bash
flutter run --flavor client -t lib/main.dart
flutter run --flavor admin -t lib/main_admin.dart
flutter build apk --flavor client -t lib/main.dart       # -> build/app/outputs/flutter-apk/app-client-release.apk
flutter build apk --flavor admin -t lib/main_admin.dart  # -> build/app/outputs/flutter-apk/app-admin-release.apk
```

Flavors are defined in `android/app/build.gradle.kts` (application IDs
`com.example.meal_reservation_tennis.client` / `.admin`); each is registered
as its own Android app in the Firebase project, with its options in
`lib/firebase_options_client.dart` / `lib/firebase_options_admin.dart`.

## Structure

- `lib/data/store.dart` - the whole data layer: auth, products, slots, orders. `watch*` methods are live Firestore streams used by the screens.
- `lib/screens/` - `applicant_*` are client screens, `restaurateur_*` are admin screens.
- `lib/widgets/common.dart` - shared styled widgets; colors in `lib/theme/app_colors.dart`.
- `firestore.rules` - who can read/write what (clients only see and create their own orders; only admins edit the catalogue, dates and order status).

Firestore collections: `users/{uid}`, `admins/{uid}`, `products/{id}`,
`slots/{yyyyMMdd}`, `orders/{EVT-yyyyMMdd-NNNN}`, `counters/{yyyyMMdd}`
(reservation numbers are allocated in a transaction, so they stay unique
when several clients order at once).

## Known gaps

- The application IDs still use `com.example.*`, which the Play Store rejects. Fine for sharing APKs directly; pick a real ID (and re-register the Android apps in Firebase) before a store release.
- Release APKs are signed with the debug key (`android/app/build.gradle.kts`, `signingConfig`). Set up a real keystore before distributing widely - Android refuses to update an app signed with a different key.
- No app icon per flavor yet (drop icons into `android/app/src/client/res/mipmap-*` and `android/app/src/admin/res/mipmap-*`).
- A product's family is free text, so different spellings create separate tabs (the product form suggests existing families to limit this).
- Accounts created by the old local-only version aren't migrated; everyone signs up again.
