import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'applicant_login_screen.dart';

/// Port of MealReservationRestaurateurScheduleManagementActivity.kt.
/// The original activity only wires the logout button: the date picker,
/// the two service checkboxes, the "Enregistrer la plage" button and the
/// event-slots RecyclerView are all inert in the real app (no click
/// listener, no adapter). Kept as static/local-only UI here for fidelity.
class RestaurateurScheduleManagementScreen extends StatefulWidget {
  const RestaurateurScheduleManagementScreen({super.key});

  @override
  State<RestaurateurScheduleManagementScreen> createState() =>
      _RestaurateurScheduleManagementScreenState();
}

class _RestaurateurScheduleManagementScreenState
    extends State<RestaurateurScheduleManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _midi = false;
  bool _soir = false;

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dates et services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardOverlay,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Date d'evenement", style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.amberHoney,
                        onPrimary: AppColors.prussianBlue,
                        surface: AppColors.prussianBlue,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: SizedBox(
                      height: 320,
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 2),
                        onDateChanged: (d) => setState(() => _selectedDate = d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Services disponibles', style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                  CheckboxListTile(
                    value: _midi,
                    onChanged: (v) => setState(() => _midi = v ?? false),
                    title: const Text('Service midi', style: TextStyle(color: Colors.white)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _soir,
                    onChanged: (v) => setState(() => _soir = v ?? false),
                    title: const Text('Service soir', style: TextStyle(color: Colors.white)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Enregistrer la plage'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dates configurees',
              style: TextStyle(color: AppColors.amberHoney, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              alignment: Alignment.center,
              child: const Text('Aucune date configuree', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
