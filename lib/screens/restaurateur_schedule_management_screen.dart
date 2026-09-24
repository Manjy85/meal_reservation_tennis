import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Where the restaurateur opens dates/services for booking. Picking a date
/// that is already open pre-selects its services, so the same form edits it.
class RestaurateurScheduleManagementScreen extends StatefulWidget {
  const RestaurateurScheduleManagementScreen({super.key});

  @override
  State<RestaurateurScheduleManagementScreen> createState() => _RestaurateurScheduleManagementScreenState();
}

class _RestaurateurScheduleManagementScreenState extends State<RestaurateurScheduleManagementScreen> {
  late final Stream<List<AvailableSlot>> _slots = MealReservationStore.watchAvailableSlots();
  List<AvailableSlot> _latestSlots = const [];

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _midi = false;
  bool _soir = false;
  bool _saving = false;

  static String _dateKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _formattedDateOf(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime _dateOfKey(String key) =>
      DateTime(int.parse(key.substring(0, 4)), int.parse(key.substring(4, 6)), int.parse(key.substring(6, 8)));

  AvailableSlot? get _existing {
    final key = _dateKeyOf(_selectedDate);
    for (final s in _latestSlots) {
      if (s.dateKey == key) return s;
    }
    return null;
  }

  void _selectDate(DateTime d) {
    setState(() {
      _selectedDate = d;
      final existing = _existing;
      _midi = existing?.services.contains('Midi') ?? false;
      _soir = existing?.services.contains('Soir') ?? false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final services = [if (_midi) 'Midi', if (_soir) 'Soir'];
    if (services.isEmpty) {
      _snack('Sélectionne au moins un service');
      return;
    }
    setState(() => _saving = true);
    try {
      await MealReservationStore.saveAvailableSlot(
        AvailableSlot(
          dateKey: _dateKeyOf(_selectedDate),
          date: _formattedDateOf(_selectedDate),
          services: services,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Échec de l’enregistrement : $e');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _snack('${formatLongDate(_formattedDateOf(_selectedDate))} ouvert à la réservation');
  }

  Future<void> _delete(AvailableSlot slot) async {
    try {
      await MealReservationStore.deleteAvailableSlot(slot.dateKey);
      if (mounted) _snack('${formatLongDate(slot.date)} fermé à la réservation');
    } catch (e) {
      if (mounted) _snack('Échec de la suppression : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dates et services')),
      body: StreamBuilder<List<AvailableSlot>>(
        stream: _slots,
        builder: (context, snapshot) {
          _latestSlots = snapshot.data ?? const [];
          final todayKey = _dateKeyOf(DateTime.now());
          final upcoming = _latestSlots.where((s) => s.dateKey.compareTo(todayKey) >= 0).toList();
          final past = _latestSlots.where((s) => s.dateKey.compareTo(todayKey) < 0).toList().reversed.toList();
          final existing = _existing;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CalendarDatePicker(
                        key: ValueKey(_selectedDate),
                        initialDate: _selectedDate,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 2),
                        onDateChanged: _selectDate,
                      ),
                      const Divider(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatLongDate(_formattedDateOf(_selectedDate)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              existing == null ? 'Fermé à la réservation' : 'Ouvert : ${existing.services.join(' et ')}',
                              style: TextStyle(color: existing == null ? AppColors.textMuted : AppColors.success),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _ServiceToggle(
                                    label: 'Midi',
                                    icon: Icons.wb_sunny_rounded,
                                    selected: _midi,
                                    onTap: () => setState(() => _midi = !_midi),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ServiceToggle(
                                    label: 'Soir',
                                    icon: Icons.nightlight_round,
                                    selected: _soir,
                                    onTap: () => setState(() => _soir = !_soir),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AppPrimaryButton(
                              label: existing == null ? 'Ouvrir cette date' : 'Mettre à jour',
                              icon: Icons.event_available_rounded,
                              loading: _saving,
                              onPressed: _save,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (snapshot.hasError) AppErrorView(snapshot.error),
              AppSectionTitle('Dates ouvertes (${upcoming.length})'),
              if (!snapshot.hasData && !snapshot.hasError)
                appLoader
              else if (upcoming.isEmpty)
                const AppEmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Aucune date ouverte',
                  message: 'Choisis une date dans le calendrier et ouvre le service midi et/ou soir.',
                )
              else
                ...upcoming.map((s) => _SlotTile(slot: s, onTap: () => _selectDate(_dateOfKey(s.dateKey)), onDelete: _delete)),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                const AppSectionTitle('Dates passées'),
                ...past.take(5).map((s) => _SlotTile(slot: s, past: true, onDelete: _delete)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceToggle({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.amber.withValues(alpha: 0.15) : AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.amber : Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.amber : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.amber : null)),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded, size: 18, color: AppColors.amber),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final AvailableSlot slot;
  final bool past;
  final VoidCallback? onTap;
  final ValueChanged<AvailableSlot> onDelete;

  const _SlotTile({required this.slot, required this.onDelete, this.past = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          DateBadge(slot.date, muted: past),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatLongDate(slot.date),
                  style: TextStyle(fontWeight: FontWeight.w700, color: past ? AppColors.textMuted : null),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: slot.services
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
            tooltip: 'Fermer cette date',
            onPressed: () => onDelete(slot),
          ),
        ],
      ),
    );
  }
}
