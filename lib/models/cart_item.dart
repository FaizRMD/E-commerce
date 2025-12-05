// lib/models/cart_item.dart

import 'package:uts_flutter_1/models/product.dart';

/// Item keranjang yang disimpan di sisi client.
///
/// Bisa saja nanti disimpan juga ke Supabase (tabel `carts`),
/// tapi model ini hanya bergantung ke [AppProduct], bukan langsung ke tabel.
class CartItemModel {
  /// Produk yang ada di keranjang.
  final AppProduct product;

  /// Jumlah item produk tersebut.
  final int quantity;

  const CartItemModel({required this.product, required this.quantity});

  /// Menghasilkan salinan [CartItemModel] dengan perubahan sebagian field.
  CartItemModel copyWith({AppProduct? product, int? quantity}) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Total harga untuk baris ini (price * quantity).
  int get lineTotal => product.price * quantity;
}
