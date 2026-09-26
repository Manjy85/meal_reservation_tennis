import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Full view of one order for the restaurateur: progress, client contact,
/// items, price check and status selection.
class RestaurateurOrderDetailScreen extends StatefulWidget {
  final String reservationNumber;

  const RestaurateurOrderDetailScreen({super.key, required this.reservationNumber});

  @override
  State<RestaurateurOrderDetailScreen> createState() => _RestaurateurOrderDetailScreenState();
}

class _RestaurateurOrderDetailScreenState extends State<RestaurateurOrderDetailScreen> {
  OrderHistoryEntry? _order;
  List<String> _priceIssues = const [];
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
    var priceIssues = const <String>[];
    try {
      order = await MealReservationStore.getOrder(widget.reservationNumber);
      if (order != null) priceIssues = _checkPrices(order, await MealReservationStore.getProducts());
    } catch (_) {
      order = null;
    }
    if (!mounted) return;
    setState(() {
      _order = order;
      _priceIssues = priceIssues;
      _selectedStatus = orderStatuses.contains(order?.status) ? order?.status : orderStatuses.first;
      _loading = false;
    });
  }

  /// The client app computes prices itself and the security rules can't
  /// check each line, so compare the order with the catalogue here. A price
  /// changed in the catalogue after the order was placed also shows up.
  static List<String> _checkPrices(OrderHistoryEntry order, List<Product> catalogue) {
    final issues = <String>[];
    final byId = {for (final p in catalogue) p.id: p};
    for (final line in order.products) {
      final product = byId[line.productId];
      if (line.productId.isEmpty || product == null) continue;
      if ((product.unitPrice - line.unitPrice).abs() > 0.005) {
        issues.add('${line.name} : ${formatEur(line.unitPrice)} dans la commande, '
            '${formatEur(product.unitPrice)} sur la carte');
      }
    }
    final linesTotal = order.products.fold(0.0, (acc, p) => acc + p.qty * p.unitPrice);
    if ((linesTotal - order.total).abs() > 0.005) {
      issues.add('Total de ${formatEur(order.total)} alors que les articles font ${formatEur(linesTotal)}');
    }
    return issues;
  }

  Future<void> _updateStatus() async {
    final order = _order;
    final status = _selectedStatus;
    if (order == null || status == null) return;
    setState(() => _updating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MealReservationStore.updateOrderStatus(order.reservationNumber, status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      messenger.showSnackBar(SnackBar(content: Text('Échec de la mise à jour : $e')));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text('Statut : ${orderStatusStyle(status).label}')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text(order?.reservationNumber ?? 'Commande')),
      body: _loading
          ? appLoader
          : order == null
              ? const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Commande introuvable',
                  message: 'Elle a peut-être été supprimée.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DateBadge(order.date),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formatLongDate(order.date), style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 2),
                                    Text('Service du ${order.service.toLowerCase()}',
                                        style: const TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              StatusChip(order.status),
                            ],
                          ),
                          const SizedBox(height: 18),
                          OrderProgress(status: order.status, statuses: orderStatuses),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const AppSectionTitle('Client'),
                    AppCard(
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.person_outline_rounded, text: order.clientName),
                          _InfoRow(icon: Icons.mail_outline_rounded, text: order.email),
                          _InfoRow(icon: Icons.phone_outlined, text: order.clientPhone),
                        ],
                      ),
                    ),
                    if (_priceIssues.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _PriceWarning(issues: _priceIssues),
                    ],
                    const SizedBox(height: 8),
                    const AppSectionTitle('Articles'),
                    AppCard(
                      child: Column(
                        children: [
                          ...order.products.where((p) => p.qty > 0).map(
                                (p) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Text('${p.qty}×',
                                          style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800)),
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
                              const Expanded(
                                child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                              ),
                              Text(
                                formatEur(order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const AppSectionTitle('Statut'),
                    ...orderStatuses.map(
                      (status) => _StatusOption(
                        status: status,
                        selected: status == _selectedStatus,
                        onTap: () => setState(() => _selectedStatus = status),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: order == null
          ? null
          : AppBottomBar(
              child: AppPrimaryButton(
                label: 'Enregistrer le statut',
                loading: _updating,
                onPressed: _selectedStatus == order.status ? null : _updateStatus,
              ),
            ),
    );
  }
}

class _PriceWarning extends StatelessWidget {
  final List<String> issues;

  const _PriceWarning({required this.issues});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 10),
              Expanded(
                child: Text('Prix à vérifier', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $issue'),
              )),
          const SizedBox(height: 8),
          const Text(
            'Encaisse le prix de la carte. Si tu n’as pas modifié ce prix depuis la commande, '
            'elle a pu être falsifiée.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(text.isEmpty ? '–' : text)),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = orderStatusStyle(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? style.color.withValues(alpha: 0.14) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? style.color : AppColors.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(style.icon, color: style.color),
                const SizedBox(width: 12),
                Expanded(child: Text(style.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? style.color : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
