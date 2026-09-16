import 'package:flutter/material.dart';

import 'screens/applicant_login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const MealReservationApp());
}

class MealReservationApp extends StatelessWidget {
  const MealReservationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMC App',
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
      home: const ApplicantLoginScreen(),
    );
  }
}
