import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'applicant_product_catalogue_screen.dart';

/// Client home, two tabs: "Réserver" (dates opened by the restaurateur) and
/// "Mes commandes" (live status of the client's orders). Both are live
/// Firestore streams, so admin-side changes show up immediately.
class ApplicantHomeScreen extends StatefulWidget {
  final int initialTab;

  const ApplicantHomeScreen({super.key, this.initialTab = 0});

  @override
  State<ApplicantHomeScreen> createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen> {
  late final Future<Account?> _account = MealReservationStore.getCurrentAccount();
  late final Stream<List<AvailableSlot>> _slots = MealReservationStore.watchAvailableSlots();
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchMyOrders();
  late int _tab = widget.initialTab;

  Future<void> _logout() async {
    await MealReservationStore.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  void _openCatalogue(AvailableSlot slot, String service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantProductCatalogueScreen(selectedDate: slot.date, selectedService: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Réserver' : 'Mes commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _BookTab(account: _account, slots: _slots, onBook: _openCatalogue),
          _OrdersTab(orders: _orders, onBrowse: () => setState(() => _tab = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Réserver',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Mes commandes',
          ),
        ],
      ),
    );
  }
}

// ---- "Réserver" tab ---------------------------------------------------------

class _BookTab extends StatelessWidget {
  final Future<Account?> account;
  final Stream<List<AvailableSlot>> slots;
  final void Function(AvailableSlot slot, String service) onBook;

  const _BookTab({required this.account, required this.slots, required this.onBook});

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        FutureBuilder<Account?>(
          future: account,
          builder: (context, snapshot) {
            final name = snapshot.data?.firstName ?? '';
            return _Greeting(firstName: name);
          },
        ),
        const SizedBox(height: 24),
        const AppSectionTitle('Prochaines dates'),
        StreamBuilder<List<AvailableSlot>>(
          stream: slots,
          builder: (context, snapshot) {
            if (snapshot.hasError) return AppErrorView(snapshot.error);
            if (!snapshot.hasData) return appLoader;
            final today = _todayKey;
            final upcoming = snapshot.data!.where((s) => s.dateKey.compareTo(today) >= 0).toList();
            if (upcoming.isEmpty) {
              return const AppEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Aucune date ouverte pour le moment',
                message: 'Le restaurateur n’a pas encore ouvert de réservations. Reviens bientôt !',
              );
            }
            return Column(
              children: upcoming.map((slot) => _SlotCard(slot: slot, onBook: onBook)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final String firstName;
  const _Greeting({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amber.withValues(alpha: 0.22), AppColors.surface],
        ),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? 'Bonjour !' : 'Bonjour $firstName !',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisis une date et un service, on s’occupe du reste.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.amber),
        ],
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
    return AppCard(
      child: Row(
        children: [
          DateBadge(slot.date),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatLongDate(slot.date), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slot.services
                      .map((service) => ActionChip(
                            avatar: Icon(
                              service == 'Soir' ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                              size: 18,
                              color: AppColors.amber,
                            ),
                            label: Text(service),
                            onPressed: () => onBook(slot, service),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// ---- "Mes commandes" tab ----------------------------------------------------

class _OrdersTab extends StatelessWidget {
  final Stream<List<OrderHistoryEntry>> orders;
  final VoidCallback onBrowse;

  const _OrdersTab({required this.orders, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderHistoryEntry>>(
      stream: orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) return AppErrorView(snapshot.error);
        if (!snapshot.hasData) return appLoader;
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Aucune commande',
                  message: 'Tes commandes et leur suivi apparaîtront ici.',
                ),
                TextButton(onPressed: onBrowse, child: const Text('Voir les dates disponibles')),
              ],
            ),
          );
        }
        final active = list.where((o) => o.status != 'Remise').toList();
        final past = list.where((o) => o.status == 'Remise').toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (active.isNotEmpty) ...[
              const AppSectionTitle('En cours'),
              ...active.map((o) => _OrderCard(order: o, showProgress: true)),
            ],
            if (past.isNotEmpty) ...[
              if (active.isNotEmpty) const SizedBox(height: 12),
              const AppSectionTitle('Historique'),
              ...past.map((o) => _OrderCard(order: o, showProgress: false)),
            ],
          ],
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderHistoryEntry order;
  final bool showProgress;

  const _OrderCard({required this.order, required this.showProgress});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showOrderDetailsSheet(context, order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DateBadge(order.date, muted: !showProgress),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatLongDate(order.date)} · ${order.service}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.reservationNumber} · ${formatEur(order.total)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (showProgress)
            OrderProgress(status: order.status, statuses: orderStatuses)
          else
            StatusChip(order.status),
        ],
      ),
    );
  }
}

void showOrderDetailsSheet(BuildContext context, OrderHistoryEntry order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.reservationNumber, style: Theme.of(context).textTheme.titleLarge),
                ),
                StatusChip(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatLongDate(order.date)} · ${order.service}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OrderProgress(status: order.status, statuses: orderStatuses),
            const SizedBox(height: 24),
            const Text('Articles', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...order.products.where((p) => p.qty > 0).map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text('${p.qty}×', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p.name)),
                        Text(formatEur(p.qty * p.unitPrice)),
                      ],
                    ),
                  ),
                ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                Text(
                  formatEur(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.amber),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
