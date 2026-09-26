import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_check.dart';
import 'data/store.dart';
import 'firebase_options_admin.dart';
import 'main.dart';
import 'screens/restaurateur_dashboard_screen.dart';
import 'screens/restaurateur_login_screen.dart';

/// ADMIN app entry point: what the restaurateur/staff installs. Starts on
/// the restaurateur login (or the dashboard if an admin session is still
/// active), no client screens involved.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: AdminFirebaseOptions.currentPlatform);
  await activateAppCheck();
  await MealReservationStore.waitForAuthRestore();

  var isAdmin = false;
  if (MealReservationStore.isSignedIn) {
    try {
      isAdmin = await MealReservationStore.isCurrentUserAdmin();
    } catch (_) {
      isAdmin = false;
    }
    if (!isAdmin) await MealReservationStore.signOut();
  }

  runApp(MealReservationApp(
    title: 'Reservation Repas Admin',
    home: isAdmin ? const RestaurateurDashboardScreen() : const RestaurateurLoginScreen(),
  ));
}
