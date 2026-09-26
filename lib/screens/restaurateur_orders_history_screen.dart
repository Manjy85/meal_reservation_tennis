import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_order_detail_screen.dart';

/// Orders already handed over (status "Remise"), most recent first, loaded
/// 20 at a time ("Voir plus") so opening it costs the same however long the
/// history is. Not live: pull down to refresh.
class RestaurateurOrdersHistoryScreen extends StatefulWidget {
  const RestaurateurOrdersHistoryScreen({super.key});

  @override
  State<RestaurateurOrdersHistoryScreen> createState() => _RestaurateurOrdersHistoryScreenState();
}

class _RestaurateurOrdersHistoryScreenState extends State<RestaurateurOrdersHistoryScreen> {
  final List<OrderHistoryEntry> _orders = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await MealReservationStore.getHistoryPage(after: _cursor);
      if (!mounted) return;
      setState(() {
        _orders.addAll(page.orders);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _orders.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  void _openDetail(OrderHistoryEntry order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurateurOrderDetailScreen(reservationNumber: order.reservationNumber)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_orders.isEmpty && _loading) {
      body = appLoader;
    } else if (_orders.isEmpty && _error != null) {
      body = ListView(children: [AppErrorView(_error)]);
    } else if (_orders.isEmpty) {
      body = ListView(
        children: const [
          AppEmptyState(
            icon: Icons.history_rounded,
            title: 'Aucune commande remise',
            message: 'Les commandes passées au statut « Remise » sont archivées ici.',
          ),
        ],
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _orders.length + 1,
        itemBuilder: (context, i) {
          if (i < _orders.length) {
            return OrderListItem(order: _orders[i], onTap: () => _openDetail(_orders[i]));
          }
          return _PageFooter(
            loading: _loading,
            hasMore: _hasMore,
            error: _error,
            count: _orders.length,
            onMore: _loadMore,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }
}

class _PageFooter extends StatelessWidget {
  final bool loading;
  final bool hasMore;
  final Object? error;
  final int count;
  final VoidCallback onMore;

  const _PageFooter({
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.count,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return appLoader;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Chargement impossible : $error', textAlign: TextAlign.center),
            ),
          if (hasMore)
            AppSecondaryButton(label: 'Voir plus', icon: Icons.expand_more_rounded, onPressed: onMore)
          else
            Text(
              count > 1 ? '$count commandes remises' : '$count commande remise',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
