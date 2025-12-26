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

/// Model untuk Voucher/Promo Code yang dapat digunakan di checkout
class AppPromotion {
  final int id;
  final String code; // kode unik (e.g., 'PROMO2025')
  final String title; // nama promo (e.g., 'Diskon Natal')
  final String? description; // deskripsi singkat
  final String discountType; // 'percentage' atau 'fixed'
  final int
  discountValue; // nilai diskon (e.g., 10 untuk 10% atau 10000 untuk Rp10k)
  final int minPurchase; // minimal pembelian untuk bisa pakai promo
  final int maxUsage; // maksimal penggunaan (0 = unlimited)
  final int usedCount; // berapa kali sudah dipakai
  final DateTime validFrom; // tanggal mulai berlaku
  final DateTime validUntil; // tanggal habis berlaku
  final bool active; // apakah promo aktif
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppPromotion({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minPurchase,
    required this.maxUsage,
    required this.usedCount,
    required this.validFrom,
    required this.validUntil,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse dari response Supabase
  factory AppPromotion.fromJson(Map<String, dynamic> json) {
    return AppPromotion(
      id: json['id'] as int,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: json['discount_value'] as int,
      minPurchase: json['min_purchase'] as int? ?? 0,
      maxUsage: json['max_usage'] as int? ?? 0,
      usedCount: json['used_count'] as int? ?? 0,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Konversi ke JSON untuk insert/update
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_purchase': minPurchase,
      'max_usage': maxUsage,
      'used_count': usedCount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'active': active,
    };
  }

  /// Check apakah promo masih berlaku
  bool get isValid {
    final now = DateTime.now();
    return active &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        (maxUsage == 0 || usedCount < maxUsage);
  }

  /// Hitung diskon berdasarkan subtotal
  int calculateDiscount(int subtotal) {
    if (!isValid || subtotal < minPurchase) return 0;

    if (discountType == 'percentage') {
      return (subtotal * discountValue ~/ 100).toInt();
    } else {
      // fixed discount
      return discountValue;
    }
  }
}
