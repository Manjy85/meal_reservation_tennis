import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/store.dart';
import 'firebase_options_client.dart';
import 'screens/applicant_home_screen.dart';
import 'screens/applicant_login_screen.dart';
import 'theme/app_colors.dart';

/// Default entry point: the CLIENT app (members book/track their meals).
/// The admin/restaurateur app is a separate entry point, see main_admin.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: ClientFirebaseOptions.currentPlatform);
  await MealReservationStore.waitForAuthRestore();

  runApp(MealReservationApp(
    title: 'Reservation Repas',
    home: MealReservationStore.isSignedIn
        ? const ApplicantHomeScreen()
        : const ApplicantLoginScreen(),
  ));
}

/// Shared app shell (theme, MaterialApp) for both the client and admin
/// builds - only the title and the start screen differ between them.
class MealReservationApp extends StatelessWidget {
  final String title;
  final Widget home;

  const MealReservationApp({
    super.key,
    required this.title,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.prussianBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.amberHoney,
          brightness: Brightness.dark,
          primary: AppColors.amberHoney,
        ).copyWith(surface: AppColors.prussianBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.prussianBlue,
          elevation: 0,
          foregroundColor: AppColors.amberHoney,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.amberHoney,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.mintCream,
              displayColor: AppColors.amberHoney,
            ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.amberHoney),
          trackColor: WidgetStateProperty.all(AppColors.hintWhite),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all(AppColors.prussianBlue),
          fillColor: WidgetStateProperty.all(AppColors.amberHoney),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(AppColors.amberHoney),
        ),
      ),
      home: home,
    );
  }
}
