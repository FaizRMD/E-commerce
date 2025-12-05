// lib/models/product.dart

/// Model produk untuk UI e-commerce.
///
/// Dipakai di:
/// - Home (recommended for you)
/// - Product detail
/// - Cart / order.
class AppProduct {
  final int id;
  final String name;
  final int price;
  final bool isBestSeller;
  final bool isActive;

  /// Nama kategori hasil join dengan tabel `categories`.
  final String? categoryName;

  /// URL gambar utama dari kolom `image_url`.
  final String? imageUrl;

  /// URL gambar kedua (opsional, kolom `image_url_2` di Supabase).
  final String? imageUrl2;

  /// Deskripsi produk dari kolom `description`.
  final String? description;

  /// Rating rata-rata (opsional).
  final double? rating;

  /// Jumlah review (opsional).
  final int? ratingCount;

  AppProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.isBestSeller,
    required this.isActive,
    this.categoryName,
    this.imageUrl,
    this.imageUrl2,
    this.description,
    this.rating,
    this.ratingCount,
  });

  /// Mapping dari row tabel `products` saja.
  factory AppProduct.fromMap(Map<String, dynamic> map) {
    return AppProduct(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
      isBestSeller: (map['is_best_seller'] ?? false) as bool,
      isActive: (map['is_active'] ?? true) as bool,
      imageUrl: map['image_url'] as String?,
      imageUrl2: map['image_url_2'] as String?, // <- kolom opsional
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      ratingCount: map['rating_count'] as int?,
    );
  }

  /// Mapping dari join `products` dan `categories`.
  ///
  /// Contoh select Supabase:
  /// `select('*, categories(name)')`
  factory AppProduct.fromJoinedMap(Map<String, dynamic> map) {
    final categories = map['categories'] as Map<String, dynamic>?;

    return AppProduct(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
      isBestSeller: (map['is_best_seller'] ?? false) as bool,
      isActive: (map['is_active'] ?? true) as bool,
      imageUrl: map['image_url'] as String?,
      imageUrl2: map['image_url_2'] as String?, // <- kolom opsional
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      ratingCount: map['rating_count'] as int?,
      categoryName: categories != null ? categories['name'] as String : null,
    );
  }

  /// Map untuk insert/update ke Supabase (kalau perlu).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'is_best_seller': isBestSeller,
      'is_active': isActive,
      'image_url': imageUrl,
      'image_url_2': imageUrl2,
      'description': description,
      'rating': rating,
      'rating_count': ratingCount,
    };
  }
}
