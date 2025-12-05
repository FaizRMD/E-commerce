// lib/core/cart_manager.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Manager keranjang belanja.
/// - Menyimpan ID order yang status-nya 'cart' di tabel `orders`.
/// - Menyimpan item di `order_items`.
/// - Menyediakan notifier untuk badge di icon cart.
class CartManager {
  CartManager._();

  static final CartManager instance = CartManager._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// id order (uuid) yang status-nya 'cart'
  String? _currentCartOrderId;

  /// Total qty item di keranjang (buat badge di icon)
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  /// Dipanggil saat app start / user masuk ke home.
  /// Baca keranjang terakhir milik user dari Supabase.
  Future<void> initFromServer() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _currentCartOrderId = null;
      cartCountNotifier.value = 0;
      return;
    }

    // Cari order terakhir dengan status 'cart'
    final List<dynamic> orders = await _supabase
        .from('orders')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'cart')
        .order('created_at', ascending: false)
        .limit(1);

    if (orders.isEmpty) {
      _currentCartOrderId = null;
      cartCountNotifier.value = 0;
      return;
    }

    final Map<String, dynamic> map = orders.first;
    final String orderId = map['id'] as String;
    _currentCartOrderId = orderId;

    // Hitung total qty dari order_items
    final List<dynamic> items = await _supabase
        .from('order_items')
        .select('qty')
        .eq('order_id', orderId);

    int totalQty = 0;
    for (final Map<String, dynamic> r in items) {
      totalQty += (r['qty'] as int? ?? 0);
    }
    cartCountNotifier.value = totalQty;
  }

  /// Tambah produk ke keranjang.
  /// Kalau belum punya order 'cart', akan dibuatkan dulu.
  Future<void> addProduct(AppProduct product, {int qty = 1}) async {
    if (qty <= 0) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu');
    }

    // 1. Pastikan sudah ada order 'cart'
    String? orderId = _currentCartOrderId;
    if (orderId == null) {
      final userName =
          (user.userMetadata?['full_name'] as String?) ?? user.email ?? 'User';

      final Map<String, dynamic> inserted = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'user_name': userName,
            'customer_name': userName,
            'status': 'cart',
            'payment_method': 'cash',
            'total': 0,
            'total_amount': 0,
          })
          .select('id')
          .single();

      orderId = inserted['id'] as String;
      _currentCartOrderId = orderId;
    }

    final int price = product.price;

    // 2. Cek apakah produk sudah ada di order_items
    final List<dynamic> existing = await _supabase
        .from('order_items')
        .select('id, qty')
        .eq('order_id', orderId)
        .eq('product_id', product.id);

    if (existing.isEmpty) {
      // insert baru
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': product.id,
        'qty': qty,
        'price': price,
        'subtotal': price * qty,
      });
    } else {
      final Map<String, dynamic> row = existing.first;
      final int oldQty = row['qty'] as int? ?? 0;
      final int newQty = oldQty + qty;

      await _supabase
          .from('order_items')
          .update({'qty': newQty, 'subtotal': newQty * price})
          .eq('id', row['id']);
    }

    // 3. Recalculate total order dan badge
    await _recalculateTotals(orderId);
  }

  /// Mengambil item keranjang untuk ditampilkan di sheet / halaman cart.
  ///
  /// Hasilnya list map: {name, imageUrl, qty, price, subtotal}
  Future<List<Map<String, dynamic>>> fetchCartItems() async {
    final orderId = _currentCartOrderId;
    if (orderId == null) return [];

    final List<dynamic> rows = await _supabase
        .from('order_items')
        .select('qty, price, subtotal, products(name, image_url)')
        .eq('order_id', orderId);

    return rows.map<Map<String, dynamic>>((raw) {
      final Map<String, dynamic> map = raw;
      final Map<String, dynamic>? product =
          map['products'] as Map<String, dynamic>?;

      return {
        'name': product?['name'] as String? ?? 'Produk',
        'imageUrl': product?['image_url'] as String?,
        'qty': map['qty'] as int? ?? 0,
        'price': map['price'] as int? ?? 0,
        'subtotal': map['subtotal'] as int? ?? 0,
      };
    }).toList();
  }

  /// Kosongkan keranjang (opsional, misal setelah checkout).
  Future<void> clearCart() async {
    final orderId = _currentCartOrderId;
    if (orderId == null) return;

    await _supabase.from('order_items').delete().eq('order_id', orderId);

    await _supabase
        .from('orders')
        .update({'status': 'cleared', 'total': 0, 'total_amount': 0})
        .eq('id', orderId);

    _currentCartOrderId = null;
    cartCountNotifier.value = 0;
  }

  /// Hitung ulang total_amount di orders + update badge qty.
  Future<void> _recalculateTotals(String orderId) async {
    final List<dynamic> rows = await _supabase
        .from('order_items')
        .select('qty, subtotal')
        .eq('order_id', orderId);

    int totalAmount = 0;
    int totalQty = 0;

    for (final Map<String, dynamic> r in rows) {
      totalQty += (r['qty'] as int? ?? 0);
      totalAmount += (r['subtotal'] as int? ?? 0);
    }

    await _supabase
        .from('orders')
        .update({'total_amount': totalAmount, 'total': totalAmount})
        .eq('id', orderId);

    cartCountNotifier.value = totalQty;
  }
}
