import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';

/// Port of MealReservationRestaurateurScheduleManagementActivity.kt, now
/// wired to real persistence: this is where the restaurateur decides which
/// dates/services clients are allowed to book (read by ApplicantHomeScreen).
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
  bool _saving = false;

  List<AvailableSlot> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loading = true);
    final slots = await MealReservationLocalStore.getAvailableSlots();
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _loading = false;
    });
  }

  String _dateKeyOf(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  String _formattedDateOf(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$day/$m/${d.year}';
  }

  Future<void> _saveSlot() async {
    final services = [
      if (_midi) 'Midi',
      if (_soir) 'Soir',
    ];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionne au moins un service')),
      );
      return;
    }

    setState(() => _saving = true);
    await MealReservationLocalStore.saveAvailableSlot(
      AvailableSlot(
        dateKey: _dateKeyOf(_selectedDate),
        date: _formattedDateOf(_selectedDate),
        services: services,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _midi = false;
      _soir = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plage enregistree')),
    );
    _loadSlots();
  }

  Future<void> _deleteSlot(AvailableSlot slot) async {
    await MealReservationLocalStore.deleteAvailableSlot(slot.dateKey);
    _loadSlots();
  }

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
                  AppPrimaryButton(
                    label: _saving ? 'Enregistrement...' : 'Enregistrer la plage',
                    height: 48,
                    onPressed: _saving ? null : _saveSlot,
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppColors.amberHoney)),
              )
            else if (_slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Aucune date configuree', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ..._slots.map(
                (slot) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardOverlay,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.date,
                              style: const TextStyle(
                                color: AppColors.amberHoney,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.services.join(' / '),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.deleteRed),
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteSlot(slot),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
