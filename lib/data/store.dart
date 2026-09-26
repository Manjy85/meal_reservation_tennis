import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared data layer for both apps, backed by Cloud Firestore (data) and
/// Firebase Auth (accounts). Both the client and admin apps read/write the
/// same collections, and the `watch*` streams push changes in real time.
/// Access control lives in firestore.rules, not here (the project is on the
/// free Spark plan, so there is no server code: the rules are the only
/// guard).
///
/// Collections: users/{uid}, admins/{uid}, products/{id}, slots/{dateKey},
/// orders/{reservationNumber}, counters/{yyyyMMdd}.

/// Order lifecycle, in order. These exact strings are stored in Firestore
/// (and 'En attente' is checked by firestore.rules) - display labels with
/// accents live in the UI layer.
const orderStatuses = ['En attente', 'En preparation', 'Prete', 'Remise'];

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

  factory Account.fromMap(Map<String, dynamic> data) => Account(
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
}

class OrderProduct {
  /// Catalogue product id; empty on orders placed before it was recorded.
  final String productId;
  final String name;
  final int qty;
  final double unitPrice;

  const OrderProduct({
    this.productId = '',
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory OrderProduct.fromMap(Map<String, dynamic> data) => OrderProduct(
        productId: data['productId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        qty: (data['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
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

  List<String> get productLines => products
      .where((p) => p.name.isNotEmpty && p.qty > 0)
      .map((p) => '${p.name} x${p.qty}')
      .toList();

  factory OrderHistoryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return OrderHistoryEntry(
      reservationNumber: doc.id,
      date: data['date'] as String? ?? '',
      service: data['service'] as String? ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      email: data['email'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      clientPhone: data['clientPhone'] as String? ?? '',
      status: data['status'] as String? ?? 'En attente',
      products: (data['products'] as List<dynamic>? ?? const [])
          .map((e) => OrderProduct.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// A page of [MealReservationStore.getHistoryPage]; `cursor` fetches the next.
class OrdersPage {
  final List<OrderHistoryEntry> orders;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;

  const OrdersPage({required this.orders, required this.cursor, required this.hasMore});
}

/// A date + set of services (Midi/Soir) opened for reservation by the
/// restaurateur. Clients can only book against these.
class AvailableSlot {
  final String dateKey; // yyyyMMdd, document id and sort key
  final String date; // dd/MM/yyyy, for display and order records
  final List<String> services; // subset of ['Midi', 'Soir']

  const AvailableSlot({
    required this.dateKey,
    required this.date,
    required this.services,
  });

  Map<String, dynamic> toMap() => {'date': date, 'services': services};

  factory AvailableSlot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AvailableSlot(
      dateKey: doc.id,
      date: data['date'] as String? ?? '',
      services: (data['services'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}

/// A menu item configured by the restaurateur. The client catalogue only
/// shows enabled ones, grouped by `category` ("famille").
class Product {
  final String id; // empty = not saved yet
  final String name;
  final String description;
  final double unitPrice;
  final bool enabled;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.enabled,
    this.category = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'unitPrice': unitPrice,
        'enabled': enabled,
        'category': category,
      };

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      enabled: data['enabled'] as bool? ?? true,
      category: data['category'] as String? ?? '',
    );
  }
}

/// Thrown for sign-in problems, with a message ready to show to the user.
class StoreAuthException implements Exception {
  final String message;
  const StoreAuthException(this.message);

  @override
  String toString() => message;
}

class MealReservationStore {
  MealReservationStore._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get _admins => _db.collection('admins');
  static CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  static CollectionReference<Map<String, dynamic>> get _slots => _db.collection('slots');
  static CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  static CollectionReference<Map<String, dynamic>> get _counters => _db.collection('counters');

  // ---- Auth ----------------------------------------------------------

  static bool get isSignedIn => _auth.currentUser != null;

  /// Waits for Firebase Auth to restore a persisted session (async on web).
  static Future<void> waitForAuthRestore() => _auth.authStateChanges().first;

  static Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }
  }

  static Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _users.doc(cred.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }
    // Best effort: the account works without it, the link just proves the
    // address belongs to the user.
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (_) {}
  }

  static Future<void> signOut() => _auth.signOut();

  /// Sends Firebase's reset link. Succeeds even for an unknown address, so
  /// the screen can't be used to find out who has an account.
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw StoreAuthException(_authMessage(e));
    }
  }

  static String get currentEmail => _auth.currentUser?.email ?? '';

  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Refreshes the cached user, e.g. after the verification link was clicked.
  /// Best effort: offline, the cached state is kept.
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (_) {}
  }

  static Future<void> resendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }
  }

  /// Updates name and phone. The email stays the account's (firestore.rules
  /// checks it matches the signed-in user).
  static Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const StoreAuthException('Session expiree, reconnecte-toi');
    final account = await getCurrentAccount();
    final email = account?.email.isNotEmpty == true ? account!.email : user.email ?? '';
    await _users.doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    });
  }

  /// Firebase requires a recent login to change the password, hence the
  /// current one.
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const StoreAuthException('Session expiree, reconnecte-toi');
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: currentPassword),
      );
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(
        e.code == 'too-many-requests' || e.code == 'network-request-failed'
            ? _authMessage(e)
            : 'Mot de passe actuel incorrect',
      );
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }
  }

  /// Permanently deletes the signed-in client's account. The password is
  /// asked again so a borrowed, unlocked phone can't be used to do it (and
  /// Firebase requires a recent login to delete a user). Past orders are
  /// kept for the restaurateur's books but stripped of personal data.
  static Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const StoreAuthException('Session expiree, reconnecte-toi');
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }

    // Orders first: once the auth user is gone, the rules no longer let us
    // touch them. A batch holds at most 500 writes.
    final orders = await _orders.where('uid', isEqualTo: user.uid).get();
    for (var i = 0; i < orders.docs.length; i += 450) {
      final batch = _db.batch();
      for (final doc in orders.docs.skip(i).take(450)) {
        batch.update(doc.reference, {
          'uid': 'deleted',
          'email': '',
          'clientName': 'Compte supprime',
          'clientPhone': '',
        });
      }
      await batch.commit();
    }
    await _users.doc(user.uid).delete();

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw StoreAuthException(_authMessage(e));
    }
  }

  /// Admin rights = a document admins/{uid} exists (created by hand in the
  /// Firebase console; clients can't write there).
  static Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return (await _admins.doc(uid).get()).exists;
  }

  static Future<Account?> getCurrentAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    return data == null ? null : Account.fromMap(data);
  }

  static String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Identifiants incorrects';
      case 'email-already-in-use':
        return 'Un compte existe deja avec cet email';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caracteres minimum)';
      case 'password-does-not-meet-requirements':
        return 'Mot de passe trop faible : allonge-le et mélange lettres, chiffres et symboles';
      case 'too-many-requests':
        return 'Trop de tentatives, reessaie dans quelques minutes';
      case 'network-request-failed':
        return 'Pas de connexion internet';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return "La connexion par email n'est pas activee dans Firebase";
      default:
        return 'Erreur de connexion (${e.code})';
    }
  }

  // ---- Products ------------------------------------------------------

  static List<Product> _sortedProducts(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(Product.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  static Stream<List<Product>> watchProducts() => _products.snapshots().map(_sortedProducts);

  static Future<List<Product>> getProducts() async => _sortedProducts(await _products.get());

  static Future<void> saveProduct(Product product) async {
    if (product.id.isEmpty) {
      await _products.add(product.toMap());
    } else {
      await _products.doc(product.id).set(product.toMap());
    }
  }

  static Future<void> deleteProduct(String id) => _products.doc(id).delete();

  // ---- Available slots -----------------------------------------------

  static Stream<List<AvailableSlot>> watchAvailableSlots() => _slots.snapshots().map(
        (snap) => snap.docs.map(AvailableSlot.fromDoc).toList()
          ..sort((a, b) => a.dateKey.compareTo(b.dateKey)),
      );

  /// Upserts by dateKey: saving an already-configured date replaces its services.
  static Future<void> saveAvailableSlot(AvailableSlot slot) =>
      _slots.doc(slot.dateKey).set(slot.toMap());

  static Future<void> deleteAvailableSlot(String dateKey) => _slots.doc(dateKey).delete();

  // ---- Orders --------------------------------------------------------

  static String _todayCompact() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Allocates the next EVT-yyyyMMdd-NNNN number and creates the order in a
  /// single transaction, so two clients ordering at once can't get the same
  /// number. firestore.rules checks the counter and the order move together
  /// and that the date/service is open. Returns the reservation number.
  static Future<String> placeOrder({
    required String date,
    required String service,
    required List<OrderProduct> products,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const StoreAuthException('Session expiree, reconnecte-toi');

    final account = await getCurrentAccount();
    final total = products.fold(0.0, (acc, p) => acc + p.qty * p.unitPrice);
    final clientName = [account?.firstName, account?.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    final today = _todayCompact();
    final counterRef = _counters.doc(today);

    return _db.runTransaction((tx) async {
      final counter = await tx.get(counterRef);
      final next = ((counter.data()?['count'] as num?)?.toInt() ?? 0) + 1;
      final number = 'EVT-$today-${next.toString().padLeft(4, '0')}';

      tx.set(counterRef, {'count': next});
      tx.set(_orders.doc(number), {
        'uid': user.uid,
        'date': date,
        'service': service,
        'total': total,
        'email': account?.email ?? user.email ?? '',
        'clientName': clientName,
        'clientPhone': account?.phone ?? '',
        'status': 'En attente',
        'products': products.map((p) => p.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return number;
    });
  }

  static List<OrderHistoryEntry> _ordersOf(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(OrderHistoryEntry.fromDoc).toList()
        ..sort((a, b) => a.reservationNumber.compareTo(b.reservationNumber));

  // Admin queries (rejected by the security rules for clients). None of them
  // reads the whole collection: a live query is billed one read per document
  // each time a screen opens it, so they stay bounded however long the
  // history gets.

  /// Orders not handed over yet, live.
  static Stream<List<OrderHistoryEntry>> watchActiveOrders() => _orders
      .where('status', whereIn: orderStatuses.where((s) => s != 'Remise').toList())
      .snapshots()
      .map(_ordersOf);

  /// Orders for one day (dd/MM/yyyy), any status, live.
  static Stream<List<OrderHistoryEntry>> watchOrdersForDate(String date) =>
      _orders.where('date', isEqualTo: date).snapshots().map(_ordersOf);

  static const historyPageSize = 20;

  /// One page of handed-over orders, most recent first. Pass the previous
  /// page's cursor to get the next one. Not live: the past doesn't change.
  /// Needs the (status, createdAt desc) index from firestore.indexes.json.
  static Future<OrdersPage> getHistoryPage({DocumentSnapshot<Map<String, dynamic>>? after}) async {
    var query = _orders
        .where('status', isEqualTo: 'Remise')
        .orderBy('createdAt', descending: true)
        .limit(historyPageSize);
    if (after != null) query = query.startAfterDocument(after);
    final snap = await query.get();
    return OrdersPage(
      orders: snap.docs.map(OrderHistoryEntry.fromDoc).toList(),
      cursor: snap.docs.isEmpty ? after : snap.docs.last,
      hasMore: snap.docs.length == historyPageSize,
    );
  }

  /// The signed-in client's own orders, most recent first.
  static Stream<List<OrderHistoryEntry>> watchMyOrders() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _orders
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => _ordersOf(snap).reversed.toList());
  }

  static Future<OrderHistoryEntry?> getOrder(String reservationNumber) async {
    final doc = await _orders.doc(reservationNumber).get();
    return doc.exists ? OrderHistoryEntry.fromDoc(doc) : null;
  }

  static Future<void> updateOrderStatus(String reservationNumber, String status) =>
      _orders.doc(reservationNumber).update({'status': status});
}
