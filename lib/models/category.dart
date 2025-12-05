// lib/models/category.dart

/// Model kategori produk pada e-commerce.
///
/// Representasi baris pada tabel `categories`.
class AppCategory {
  final int id;
  final String name;

  /// (Opsional) emoji / teks ikon.
  final String? icon;

  /// (Opsional) URL gambar kategori.
  final String? imageUrl;

  AppCategory({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
  });

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
