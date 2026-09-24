import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_catalog_management_screen.dart';
import 'restaurateur_login_screen.dart';
import 'restaurateur_orders_list_screen.dart';
import 'restaurateur_schedule_management_screen.dart';

/// Admin home, SumUp/Square-style: live counters for the order pipeline and
/// today's service, then shortcuts to each management screen.
class RestaurateurDashboardScreen extends StatefulWidget {
  const RestaurateurDashboardScreen({super.key});

  @override
  State<RestaurateurDashboardScreen> createState() => _RestaurateurDashboardScreenState();
}

class _RestaurateurDashboardScreenState extends State<RestaurateurDashboardScreen> {
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchAllOrders();

  static String get _today {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Se déconnecter',
            onPressed: () => logoutRestaurateur(context),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderHistoryEntry>>(
        stream: _orders,
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <OrderHistoryEntry>[];
          int countOf(String status) => orders.where((o) => o.status == status).length;
          final todays = orders.where((o) => o.date == _today).length;
          final active = orders.where((o) => o.status != 'Remise').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (snapshot.hasError) AppErrorView(snapshot.error),
              _TodayCard(
                loading: !snapshot.hasData && !snapshot.hasError,
                orders: todays,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatTile(status: 'En attente', count: countOf('En attente'))),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(status: 'En preparation', count: countOf('En preparation'))),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(status: 'Prete', count: countOf('Prete'))),
                ],
              ),
              const SizedBox(height: 28),
              const AppSectionTitle('Gestion'),
              _NavCard(
                icon: Icons.receipt_long_rounded,
                color: AppColors.amber,
                title: 'Commandes',
                subtitle: active == 0 ? 'Aucune commande en cours' : '$active en cours',
                badge: countOf('En attente'),
                onTap: () => _open(const RestaurateurOrdersListScreen()),
              ),
              _NavCard(
                icon: Icons.inventory_2_rounded,
                color: AppColors.info,
                title: 'Mes articles',
                subtitle: 'Carte, prix, familles et disponibilité',
                onTap: () => _open(const RestaurateurCatalogManagementScreen()),
              ),
              _NavCard(
                icon: Icons.calendar_month_rounded,
                color: AppColors.success,
                title: 'Dates et services',
                subtitle: 'Ouvrir les réservations midi / soir',
                onTap: () => _open(const RestaurateurScheduleManagementScreen()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final bool loading;
  final int orders;

  const _TodayCard({required this.loading, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amber.withValues(alpha: 0.25), AppColors.surface],
        ),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AUJOURD'HUI",
            style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(loading ? '–' : '$orders', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(width: 8),
              Text(
                orders > 1 ? 'commandes pour aujourd’hui' : 'commande pour aujourd’hui',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String status;
  final int count;

  const _StatTile({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final style = orderStatusStyle(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.color, size: 22),
          const SizedBox(height: 10),
          Text('$count', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(
            style.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '$badge',
                style: const TextStyle(color: AppColors.onAmber, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
