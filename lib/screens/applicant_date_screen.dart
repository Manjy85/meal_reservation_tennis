import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_product_catalogue_screen.dart';

/// Port of MealReservationApplicantDateActivity.kt
class ApplicantDateScreen extends StatefulWidget {
  const ApplicantDateScreen({super.key});

  @override
  State<ApplicantDateScreen> createState() => _ApplicantDateScreenState();
}

class _ApplicantDateScreenState extends State<ApplicantDateScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedService;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.amberHoney,
            onPrimary: AppColors.prussianBlue,
            surface: AppColors.prussianBlue,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDate {
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    return '$d/$m/${_selectedDate.year}';
  }

  void _continue() {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionne Midi ou Soir pour continuer')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantProductCatalogueScreen(
          selectedDate: _formattedDate,
          selectedService: _selectedService!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choix de la date et du service')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Selectionnez une date d'evenement et choisissez le service souhaite avant d'acceder au catalogue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 15),
              ),
              const SizedBox(height: 20),
              const AppFieldLabel("Date de l'evenement *"),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.amberHoney, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formattedDate,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.amberHoney, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const AppFieldLabel('Service souhaite *'),
              Row(
                children: [
                  _ServiceRadio(
                    label: 'Midi',
                    selected: _selectedService == 'Midi',
                    onTap: () => setState(() => _selectedService = 'Midi'),
                  ),
                  const SizedBox(width: 24),
                  _ServiceRadio(
                    label: 'Soir',
                    selected: _selectedService == 'Soir',
                    onTap: () => setState(() => _selectedService = 'Soir'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(label: 'Continuer', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected ? true : null,
            onChanged: (_) => onTap(),
            fillColor: WidgetStateProperty.all(AppColors.amberHoney),
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
