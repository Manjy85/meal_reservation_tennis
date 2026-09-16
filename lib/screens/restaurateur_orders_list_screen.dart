import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/order_list_item.dart';
import 'applicant_login_screen.dart';
import 'restaurateur_order_detail_screen.dart';
import 'restaurateur_orders_history_screen.dart';

/// Port of MealReservationRestaurateurOrdersListActivity.kt (orders with
/// status != "Remise"). Reloads on every return to the screen, mirroring
/// the original's onResume().
class RestaurateurOrdersListScreen extends StatefulWidget {
  const RestaurateurOrdersListScreen({super.key});

  @override
  State<RestaurateurOrdersListScreen> createState() => _RestaurateurOrdersListScreenState();
}

class _RestaurateurOrdersListScreenState extends State<RestaurateurOrdersListScreen> {
  List<OrderHistoryEntry> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final all = await MealReservationLocalStore.getOrdersHistory();
    if (!mounted) return;
    setState(() {
      _orders = all.where((o) => o.status != 'Remise').toList();
      _loading = false;
    });
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
        title: const Text('Commandes'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RestaurateurOrdersHistoryScreen()),
              );
            },
            child: const Text('Historique', style: TextStyle(color: AppColors.amberHoney)),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune commande enregistree',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return OrderListItem(
                        order: order,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RestaurateurOrderDetailScreen(
                                reservationNumber: order.reservationNumber,
                              ),
                            ),
                          );
                          _loadOrders();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
