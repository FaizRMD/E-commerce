import 'package:uts_flutter_1/models/order_item.dart';

/// Model pesanan (order) di e-commerce.
/// Mapping ke tabel `orders`.
class OrderModel {
  final String id; // uuid
  final String? userId; // auth.users.id
  final int total; // kolom `total`
  final String status; // pending, paid, dll
  final String paymentMethod;
  final DateTime createdAt;

  /// Item detail (biasanya query terpisah).
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.userId,
    this.items = const [],
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      total: map['total'] as int,
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String? ?? 'unknown',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  OrderModel copyWithItems(List<OrderItemModel> newItems) {
    return OrderModel(
      id: id,
      userId: userId,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      items: newItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
