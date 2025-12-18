// lib/core/cart_manager.dart
import 'package:flutter/foundation.dart';

import 'supabase_client.dart';
import '../models/product.dart';

/// Representasi item di keranjang (satu baris dari tabel order_items).
class CartItem {
  final int id; // order_items.id
  final String orderId; // orders.id (uuid)
  final int productId;

  final String productName;
  final String? productImageUrl;

  int quantity; // mapping ke kolom qty
  final int unitPrice; // mapping ke kolom price

  CartItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  int get lineTotal => quantity * unitPrice;
}

/// Mengelola keranjang belanja di Supabase.
class CartManager extends ChangeNotifier {
  CartManager._internal();

  static final CartManager instance = CartManager._internal();

  /// id orders (uuid) untuk order dengan status = 'cart'
  String? _currentCartOrderId;

  final List<CartItem> _items = [];

  /// Notifier jumlah qty untuk badge icon cart.
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalPrice => _items.fold<int>(0, (sum, it) => sum + it.lineTotal);

  int get totalQty => _items.fold<int>(0, (sum, it) => sum + it.quantity);

  // ---------------------------------------------------------------------------
  // INITIAL LOAD
  // ---------------------------------------------------------------------------

  /// Ambil order status 'cart' + order_items-nya untuk user saat ini.
  Future<void> initFromServer() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _currentCartOrderId = null;
      _items.clear();
      cartCountNotifier.value = 0;
      notifyListeners();
      return;
    }

    // cari order status 'cart'
    final existingOrder = await supabase
        .from('orders')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'cart')
        .limit(1);

    if (existingOrder.isEmpty) {
      _currentCartOrderId = null;
      _items.clear();
      cartCountNotifier.value = 0;
      notifyListeners();
      return;
    }

    _currentCartOrderId = existingOrder.first['id'] as String;

    // pakai order_id yang pasti non-null
    final String cartId = _currentCartOrderId!;

    final itemRows = await supabase
        .from('order_items')
        .select(
          // ⬇️ sesuai dengan tabel kamu: qty, price, subtotal
          'id, order_id, product_id, qty, price, subtotal, products(name, image_url)',
        )
        .eq('order_id', cartId);

    _items
      ..clear()
      ..addAll(
        (itemRows as List<dynamic>).map((row) {
          final map = row as Map<String, dynamic>;
          final product = map['products'] as Map<String, dynamic>?;

          return CartItem(
            id: map['id'] as int,
            orderId: map['order_id'] as String,
            productId: map['product_id'] as int,
            quantity: map['qty'] as int, // ⬅ qty
            unitPrice: map['price'] as int, // ⬅ price
            productName: product?['name'] as String? ?? 'Produk',
            productImageUrl: product?['image_url'] as String?,
          );
        }),
      );

    cartCountNotifier.value = totalQty;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // UTILS
  // ---------------------------------------------------------------------------

  /// Pastikan sudah ada order status 'cart' untuk user sekarang.
  Future<void> _ensureCartOrder() async {
    if (_currentCartOrderId != null) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu');
    }

    // cek lagi di DB, barangkali sudah ada
    final existingOrder = await supabase
        .from('orders')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'cart')
        .limit(1);

    if (existingOrder.isNotEmpty) {
      _currentCartOrderId = existingOrder.first['id'] as String;
      return;
    }

    final String userName =
        (user.userMetadata?['full_name'] as String?) ?? user.email ?? 'User';

    final insertData = <String, dynamic>{
      'user_id': user.id,
      'user_name': userName,
      'customer_name': userName,
      'status': 'cart',
      'payment_method': 'cash',
      'total': 0,
      'total_amount': 0,
      'note': null,
    };

    final inserted = await supabase
        .from('orders')
        .insert(insertData)
        .select('id')
        .single();

    _currentCartOrderId = inserted['id'] as String;
  }

  Future<void> _syncCartOrderTotals() async {
    if (_currentCartOrderId == null) return;
    final String cartId = _currentCartOrderId!;

    final int sum = totalPrice;

    await supabase
        .from('orders')
        .update({'total': sum, 'total_amount': sum})
        .eq('id', cartId);
  }

  // ---------------------------------------------------------------------------
  // MUTASI KERANJANG
  // ---------------------------------------------------------------------------

  /// Tambah produk ke keranjang.
  Future<void> addProduct(AppProduct product, {int qty = 1}) async {
    if (qty <= 0) return;

    await _ensureCartOrder();
    final String orderId = _currentCartOrderId!;

    // cek apakah sudah ada item dengan product_id ini
    final index = _items.indexWhere((item) => item.productId == product.id);

    if (index != -1) {
      // update qty + subtotal
      final existing = _items[index];
      final newQty = existing.quantity + qty;
      final newSubtotal = newQty * existing.unitPrice;

      await supabase
          .from('order_items')
          .update({'qty': newQty, 'subtotal': newSubtotal})
          .eq('id', existing.id);

      existing.quantity = newQty;
    } else {
      // insert baris baru
      final subtotal = qty * product.price;
      final insertData = <String, dynamic>{
        'order_id': orderId,
        'product_id': product.id,
        'qty': qty,
        'price': product.price,
        'subtotal': subtotal,
      };

      final inserted = await supabase
          .from('order_items')
          .insert(insertData)
          .select('id')
          .single();

      final newItem = CartItem(
        id: inserted['id'] as int,
        orderId: orderId,
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        quantity: qty,
        unitPrice: product.price,
      );
      _items.add(newItem);
    }

    await _syncCartOrderTotals();
    cartCountNotifier.value = totalQty;
    notifyListeners();
  }

  /// Ubah qty (kalau 0 atau kurang, item dihapus).
  Future<void> updateQty(int itemId, int newQty) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    if (newQty <= 0) {
      await removeItem(itemId);
      return;
    }

    final item = _items[index];
    final newSubtotal = newQty * item.unitPrice;

    await supabase
        .from('order_items')
        .update({'qty': newQty, 'subtotal': newSubtotal})
        .eq('id', itemId);

    item.quantity = newQty;
    await _syncCartOrderTotals();
    cartCountNotifier.value = totalQty;
    notifyListeners();
  }

  /// Hapus 1 item dari keranjang.
  Future<void> removeItem(int itemId) async {
    await supabase.from('order_items').delete().eq('id', itemId);
    _items.removeWhere((e) => e.id == itemId);
    await _syncCartOrderTotals();
    cartCountNotifier.value = totalQty;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CHECKOUT ITEM TERPILIH
  // ---------------------------------------------------------------------------

  /// Checkout hanya item yang dipilih (list id dari order_items).
  Future<void> checkoutSelected(List<int> selectedItemIds) async {
    if (selectedItemIds.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu');
    }

    final selectedItems = _items
        .where((item) => selectedItemIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) return;

    final int totalSelected = selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    final String userName =
        (user.userMetadata?['full_name'] as String?) ?? user.email ?? 'User';

    // 1. buat order baru (status pending / menunggu pembayaran)
    final newOrder = await supabase
        .from('orders')
        .insert(<String, dynamic>{
          'user_id': user.id,
          'user_name': userName,
          'customer_name': userName,
          'status': 'pending',
          'payment_method': 'cash',
          'total': totalSelected,
          'total_amount': totalSelected,
          'note': null,
        })
        .select('id')
        .single();

    final String newOrderId = newOrder['id'] as String;

    // 2. copy item ke order_items untuk order baru
    for (final item in selectedItems) {
      await supabase.from('order_items').insert(<String, dynamic>{
        'order_id': newOrderId,
        'product_id': item.productId,
        'qty': item.quantity,
        'price': item.unitPrice,
        'subtotal': item.lineTotal,
      });
    }

    // 3. hapus item dari keranjang (order cart)
    for (final item in selectedItems) {
      await supabase.from('order_items').delete().eq('id', item.id);
      _items.removeWhere((e) => e.id == item.id);
    }

    // 4. sinkronkan total keranjang yang tersisa
    await _syncCartOrderTotals();
    cartCountNotifier.value = totalQty;
    notifyListeners();
  }
}
