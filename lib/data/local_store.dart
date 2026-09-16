import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Port of MealReservationLocalStore.kt: everything is persisted locally
/// (SharedPreferences), there is no backend.

class Account {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const Account({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });
}

class OrderProduct {
  final String name;
  final int qty;
  final double unitPrice;

  const OrderProduct({
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory OrderProduct.fromJson(Map<String, dynamic> json) => OrderProduct(
        name: json['name'] as String? ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

class OrderHistoryEntry {
  final String reservationNumber;
  final String date;
  final String service;
  final double total;
  final String email;
  final String clientName;
  final String clientPhone;
  final String status;
  final List<OrderProduct> products;

  const OrderHistoryEntry({
    required this.reservationNumber,
    required this.date,
    required this.service,
    required this.total,
    required this.email,
    required this.clientName,
    required this.clientPhone,
    required this.status,
    required this.products,
  });

  /// "Name xQty" lines, mirrors OrderHistoryEntry.products in Kotlin.
  List<String> get productLines => products
      .where((p) => p.name.isNotEmpty && p.qty > 0)
      .map((p) => '${p.name} x${p.qty}')
      .toList();

  Map<String, dynamic> toJson() => {
        'reservationNumber': reservationNumber,
        'date': date,
        'service': service,
        'total': total,
        'email': email,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'status': status,
        'products': products.map((p) => p.toJson()).toList(),
      };

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) =>
      OrderHistoryEntry(
        reservationNumber: json['reservationNumber'] as String? ?? '',
        date: json['date'] as String? ?? '',
        service: json['service'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        email: json['email'] as String? ?? '',
        clientName: json['clientName'] as String? ?? '',
        clientPhone: json['clientPhone'] as String? ?? '',
        status: json['status'] as String? ?? 'En attente',
        products: (json['products'] as List<dynamic>? ?? const [])
            .map((e) => OrderProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MealReservationLocalStore {
  MealReservationLocalStore._();

  static const _keyAccounts = 'created_accounts';
  static const _keyCurrentAccountEmail = 'current_account_email';
  static const _keyLastOrderDay = 'last_order_day';
  static const _keyLastOrderCount = 'last_order_count';
  static const _keyOrdersHistory = 'orders_history';

  static String _todayCompact() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static Future<void> setCurrentAccountEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentAccountEmail, email);
  }

  static Future<String?> getCurrentAccountEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentAccountEmail);
  }

  static Future<List<Map<String, dynamic>>> _getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAccounts);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Account?> getCurrentAccount() async {
    final email = await getCurrentAccountEmail();
    if (email == null) return null;
    final accounts = await _getStoredAccounts();
    for (final account in accounts) {
      final accountEmail = account['email'] as String? ?? '';
      if (accountEmail.toLowerCase() == email.toLowerCase()) {
        return Account(
          firstName: account['firstName'] as String? ?? '',
          lastName: account['lastName'] as String? ?? '',
          email: accountEmail,
          phone: account['phone'] as String? ?? '',
        );
      }
    }
    return null;
  }

  /// Password if present, otherwise phone (compat with accounts created
  /// before the password field existed) - mirrors isValidLocalLogin.
  static Future<bool> validateLogin(String email, String password) async {
    final accounts = await _getStoredAccounts();
    for (final account in accounts) {
      final accountEmail = account['email'] as String? ?? '';
      if (accountEmail.toLowerCase() != email.toLowerCase()) continue;
      final storedPassword = account.containsKey('password')
          ? (account['password'] as String? ?? '')
          : (account['phone'] as String? ?? '');
      return storedPassword == password;
    }
    return false;
  }

  static Future<void> saveAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _getStoredAccounts();

    final account = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
    };

    var replaced = false;
    for (var i = 0; i < accounts.length; i++) {
      if ((accounts[i]['email'] as String? ?? '').toLowerCase() ==
          email.toLowerCase()) {
        accounts[i] = account;
        replaced = true;
        break;
      }
    }
    if (!replaced) accounts.add(account);

    await prefs.setString(_keyAccounts, jsonEncode(accounts));
  }

  static Future<String> nextReservationNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayCompact();
    final storedDay = prefs.getString(_keyLastOrderDay) ?? '';
    final nextCount =
        storedDay == today ? (prefs.getInt(_keyLastOrderCount) ?? 0) + 1 : 1;

    await prefs.setString(_keyLastOrderDay, today);
    await prefs.setInt(_keyLastOrderCount, nextCount);

    return 'EVT-$today-${nextCount.toString().padLeft(4, '0')}';
  }

  static Future<void> saveOrderHistory(OrderHistoryEntry order) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOrdersHistory);
    List<dynamic> history = [];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        history = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        history = [];
      }
    }
    history.add(order.toJson());
    await prefs.setString(_keyOrdersHistory, jsonEncode(history));
  }

  static Future<List<OrderHistoryEntry>> getOrdersHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOrdersHistory);
    if (raw == null || raw.trim().isEmpty) return [];
    List<dynamic> history;
    try {
      history = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
    final orders = history
        .map((e) => OrderHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    orders.sort((a, b) => a.reservationNumber.compareTo(b.reservationNumber));
    return orders;
  }

  static Future<OrderHistoryEntry?> findOrderByReservationNumber(
      String reservationNumber) async {
    final orders = await getOrdersHistory();
    for (final order in orders) {
      if (order.reservationNumber == reservationNumber) return order;
    }
    return null;
  }

  static Future<void> updateOrderStatus(
      String reservationNumber, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOrdersHistory);
    if (raw == null || raw.trim().isEmpty) return;
    List<dynamic> history;
    try {
      history = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    for (final entry in history) {
      final map = entry as Map<String, dynamic>;
      if (map['reservationNumber'] == reservationNumber) {
        map['status'] = status;
        break;
      }
    }
    await prefs.setString(_keyOrdersHistory, jsonEncode(history));
  }
}
