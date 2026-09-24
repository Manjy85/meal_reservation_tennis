import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_login_screen.dart';

const _statuses = ['En attente', 'En preparation', 'Prete', 'Remise'];

/// Port of MealReservationRestaurateurOrderDetailActivity.kt
class RestaurateurOrderDetailScreen extends StatefulWidget {
  final String reservationNumber;

  const RestaurateurOrderDetailScreen({super.key, required this.reservationNumber});

  @override
  State<RestaurateurOrderDetailScreen> createState() => _RestaurateurOrderDetailScreenState();
}

class _RestaurateurOrderDetailScreenState extends State<RestaurateurOrderDetailScreen> {
  OrderHistoryEntry? _order;
  bool _loading = true;
  String? _selectedStatus;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    OrderHistoryEntry? order;
    try {
      order = await MealReservationStore.getOrder(widget.reservationNumber);
    } catch (_) {
      order = null;
    }
    if (!mounted) return;
    setState(() {
      _order = order;
      _selectedStatus = _statuses.contains(order?.status) ? order?.status : _statuses.first;
      _loading = false;
    });
  }

  Future<void> _updateStatus() async {
    final order = _order;
    if (order == null || _selectedStatus == null) return;
    setState(() => _updating = true);
    try {
      await MealReservationStore.updateOrderStatus(order.reservationNumber, _selectedStatus!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec de la mise a jour: $e')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Statut mis a jour')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: () => logoutRestaurateur(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final order = _order;

    final identityJoined = order == null
        ? ''
        : [order.clientName, order.email, order.clientPhone]
            .where((s) => s.isNotEmpty)
            .join(' - ');
    final identity = identityJoined.isEmpty ? '-' : identityJoined;

    final items = order == null || order.productLines.isEmpty
        ? '- Aucun article'
        : order.productLines.map((l) => '- $l').join('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order == null
                      ? 'Reservation: introuvable'
                      : 'Reservation: ${order.reservationNumber}',
                  style: const TextStyle(
                    color: AppColors.amberHoney,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Client: $identity', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  order == null
                      ? 'Date: - | Service: -'
                      : 'Date: ${order.date.isEmpty ? '-' : order.date} | Service: ${order.service.isEmpty ? '-' : order.service}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Articles',
                  style: TextStyle(color: AppColors.amberHoney, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(items, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                Text(
                  'Total: ${formatEur(order?.total ?? 0.0)}',
                  style: const TextStyle(
                    color: AppColors.amberHoney,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Statut de la commande',
                  style: TextStyle(color: AppColors.amberHoney, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  dropdownColor: AppColors.prussianBlue,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.amberHoney),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.amberHoney, width: 2),
                    ),
                  ),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: order == null ? null : (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: _updating ? 'Mise a jour...' : 'Mettre a jour',
                  height: 48,
                  onPressed: order == null || _updating ? null : _updateStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
