class OrderItemModel {
  final int id;
  final String orderId; // uuid
  final int productId;
  final int qty;
  final int price;
  final int subtotal;

  final String? productName;
  final String? productImageUrl;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.qty,
    required this.price,
    required this.subtotal,
    this.productName,
    this.productImageUrl,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as int,
      qty: map['qty'] as int,
      price: map['price'] as int,
      subtotal: map['subtotal'] as int,
      productName: map['product_name'] as String?,
      productImageUrl: map['product_image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'qty': qty,
      'price': price,
      'subtotal': subtotal,
    };
  }

  int get lineTotal => subtotal;
}
