/// Model promo/banner di halaman home.
///
/// Cocok dengan tabel `promotions` di Supabase.
class PromotionModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int? discountPercent;
  final bool isActive;

  const PromotionModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.discountPercent,
    this.isActive = true,
  });

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      id: map['id'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      imageUrl: map['image_url'] as String?,
      discountPercent: map['discount_pct'] as int?,
      isActive: (map['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'discount_pct': discountPercent,
      'is_active': isActive,
    };
  }
}
