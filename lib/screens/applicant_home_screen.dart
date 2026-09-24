import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'applicant_product_catalogue_screen.dart';

/// Home screen shown once the client is logged in: the dates/services the
/// restaurateur opened for reservation, and the client's own orders ("bons
/// de commande"). Both are live Firestore streams, so a date opened or an
/// order status changed from the admin app shows up here immediately.
class ApplicantHomeScreen extends StatefulWidget {
  const ApplicantHomeScreen({super.key});

  @override
  State<ApplicantHomeScreen> createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen> {
  late final Future<Account?> _account = MealReservationStore.getCurrentAccount();
  late final Stream<List<AvailableSlot>> _slots = MealReservationStore.watchAvailableSlots();
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchMyOrders();

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    await MealReservationStore.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  void _bookSlot(AvailableSlot slot, String service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantProductCatalogueScreen(
          selectedDate: slot.date,
          selectedService: service,
        ),
      ),
    );
  }

  void _showOrderDetails(OrderHistoryEntry order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.prussianBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.reservationNumber,
                style: const TextStyle(
                  color: AppColors.amberHoney,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.date.isEmpty ? '-' : order.date} | ${order.service.isEmpty ? '-' : order.service}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text('Statut: ${order.status}', style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                order.productLines.isEmpty
                    ? '- Aucun article'
                    : order.productLines.map((l) => '- $l').join('\n'),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Total: ${formatEur(order.total)}',
                style: const TextStyle(
                  color: AppColors.amberHoney,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Account?>(
              future: _account,
              builder: (context, snapshot) {
                final account = snapshot.data;
                if (account == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Bonjour ${account.firstName}',
                    style: const TextStyle(
                      color: AppColors.amberHoney,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const _SectionTitle('Dates disponibles'),
            StreamBuilder<List<AvailableSlot>>(
              stream: _slots,
              builder: (context, snapshot) {
                if (snapshot.hasError) return AppErrorView(snapshot.error);
                if (!snapshot.hasData) return appLoader;
                final today = _todayKey;
                final slots = snapshot.data!.where((s) => s.dateKey.compareTo(today) >= 0).toList();
                if (slots.isEmpty) {
                  return const AppSectionCard(
                    margin: EdgeInsets.zero,
                    child: Text(
                      'Aucune date disponible pour le moment. Revenez plus tard.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }
                return Column(
                  children: slots.map((slot) => _SlotCard(slot: slot, onBook: _bookSlot)).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Mes commandes'),
            StreamBuilder<List<OrderHistoryEntry>>(
              stream: _orders,
              builder: (context, snapshot) {
                if (snapshot.hasError) return AppErrorView(snapshot.error);
                if (!snapshot.hasData) return appLoader;
                final orders = snapshot.data!;
                if (orders.isEmpty) {
                  return const AppSectionCard(
                    margin: EdgeInsets.zero,
                    child: Text(
                      'Aucune commande pour le moment.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }
                return Column(
                  children: orders
                      .map((order) => _OrderSummaryCard(
                            order: order,
                            onTap: () => _showOrderDetails(order),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.amberHoney, fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final AvailableSlot slot;
  final void Function(AvailableSlot slot, String service) onBook;

  const _SlotCard({required this.slot, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.date,
            style: const TextStyle(
              color: AppColors.amberHoney,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: slot.services
                .map(
                  (service) => ElevatedButton(
                    onPressed: () => onBook(slot, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(service),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final OrderHistoryEntry order;
  final VoidCallback onTap;

  const _OrderSummaryCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppSectionCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.reservationNumber,
                    style: const TextStyle(
                      color: AppColors.amberHoney,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.date.isEmpty ? '-' : order.date} | ${order.service.isEmpty ? '-' : order.service}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(order.status, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            Text(
              formatEur(order.total),
              style: const TextStyle(
                color: AppColors.amberHoney,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
