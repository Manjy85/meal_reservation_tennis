import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_order_detail_screen.dart';
import 'restaurateur_orders_history_screen.dart';

/// Orders still in progress (status != "Remise"), live. Filter by status
/// with the chips, and move an order forward with one tap on its card.
class RestaurateurOrdersListScreen extends StatefulWidget {
  const RestaurateurOrdersListScreen({super.key});

  @override
  State<RestaurateurOrdersListScreen> createState() => _RestaurateurOrdersListScreenState();
}

class _RestaurateurOrdersListScreenState extends State<RestaurateurOrdersListScreen> {
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchAllOrders();
  static final _filters = orderStatuses.where((s) => s != 'Remise').toList();
  String? _filter;

  Future<void> _advance(OrderHistoryEntry order) async {
    final index = orderStatuses.indexOf(order.status);
    if (index < 0 || index >= orderStatuses.length - 1) return;
    final next = orderStatuses[index + 1];
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MealReservationStore.updateOrderStatus(order.reservationNumber, next);
      messenger.showSnackBar(SnackBar(
        content: Text('${order.reservationNumber} → ${orderStatusStyle(next).label}'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => MealReservationStore.updateOrderStatus(order.reservationNumber, order.status),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Échec de la mise à jour : $e')));
    }
  }

  void _openDetail(OrderHistoryEntry order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurateurOrderDetailScreen(reservationNumber: order.reservationNumber)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestaurateurOrdersHistoryScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderHistoryEntry>>(
        stream: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorView(snapshot.error);
          if (!snapshot.hasData) return appLoader;

          final active = snapshot.data!.where((o) => o.status != 'Remise').toList();
          final visible = _filter == null ? active : active.where((o) => o.status == _filter).toList();

          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  children: [
                    _FilterChip(
                      label: 'Toutes',
                      count: active.length,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final status in _filters)
                      _FilterChip(
                        label: orderStatusStyle(status).label,
                        count: active.where((o) => o.status == status).length,
                        selected: _filter == status,
                        onTap: () => setState(() => _filter = status),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.inbox_rounded,
                        title: 'Aucune commande ici',
                        message: 'Les nouvelles commandes apparaissent automatiquement.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, i) => OrderListItem(
                          order: visible[i],
                          onTap: () => _openDetail(visible[i]),
                          onAdvance: () => _advance(visible[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label  $count'),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
