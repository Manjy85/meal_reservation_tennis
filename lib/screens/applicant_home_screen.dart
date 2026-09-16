import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'applicant_product_catalogue_screen.dart';

/// Home screen shown once the client is logged in. Shows the dates/services
/// the restaurateur opened for reservation (AvailableSlot, configured from
/// RestaurateurScheduleManagementScreen) and the client's own order
/// history ("bons de commande").
class ApplicantHomeScreen extends StatefulWidget {
  const ApplicantHomeScreen({super.key});

  @override
  State<ApplicantHomeScreen> createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen> {
  Account? _account;
  List<AvailableSlot> _slots = [];
  List<OrderHistoryEntry> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final account = await MealReservationLocalStore.getCurrentAccount();
    final slots = await MealReservationLocalStore.getAvailableSlots();
    final allOrders = await MealReservationLocalStore.getOrdersHistory();

    final email = account?.email.toLowerCase();
    final myOrders = email == null
        ? <OrderHistoryEntry>[]
        : allOrders.where((o) => o.email.toLowerCase() == email).toList().reversed.toList();

    if (!mounted) return;
    setState(() {
      _account = account;
      _slots = slots;
      _orders = myOrders;
      _loading = false;
    });
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  void _bookSlot(AvailableSlot slot, String service) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ApplicantProductCatalogueScreen(
          selectedDate: slot.date,
          selectedService: service,
        ),
      ),
    )
        .then((_) => _load());
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
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : RefreshIndicator(
                color: AppColors.amberHoney,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_account != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Bonjour ${_account!.firstName}',
                          style: const TextStyle(
                            color: AppColors.amberHoney,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Text(
                      'Dates disponibles',
                      style: TextStyle(color: AppColors.amberHoney, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_slots.isEmpty)
                      const AppSectionCard(
                        margin: EdgeInsets.zero,
                        child: Text(
                          'Aucune date disponible pour le moment. Revenez plus tard.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      )
                    else
                      ..._slots.map(
                        (slot) => AppSectionCard(
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
                                        onPressed: () => _bookSlot(slot, service),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.buttonDark,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(service),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mes commandes',
                      style: TextStyle(color: AppColors.amberHoney, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_orders.isEmpty)
                      const AppSectionCard(
                        margin: EdgeInsets.zero,
                        child: Text(
                          'Aucune commande pour le moment.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      )
                    else
                      ..._orders.map(
                        (order) => _OrderSummaryCard(
                          order: order,
                          onTap: () => _showOrderDetails(order),
                        ),
                      ),
                  ],
                ),
              ),
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
