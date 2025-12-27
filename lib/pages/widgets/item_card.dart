// lib/pages/widgets/item_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/ui_constants.dart';
import '../../core/supabase_client.dart';
import '../../core/storage_utils.dart';
import '../../models/product.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.product,
    required this.press,
    this.resolvedImageUrl,
  });

  final AppProduct product;
  final VoidCallback press;
  // optional: resolved signed URL prefetched by parent to avoid per-item FutureBuilder
  final String? resolvedImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Warna background untuk area gambar
    final Color bgColor = product.isBestSeller
        ? const Color(0xFFFFF3E0) // sedikit krem kalau best seller
        : const Color(0xFFE5E7EB); // abu muda untuk yang lain

    return GestureDetector(
      onTap: press,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ BAGIAN GAMBAR ------------------
            SizedBox(
              height: 130, // tinggi konsisten di semua card
              child: Stack(
                children: [
                  // gambar produk
                  Positioned.fill(
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Container(
                          color: bgColor,
                          child:
                              product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? _buildCachedImage()
                              : const Center(
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    size: 32,
                                    color: Colors.black38,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // badge "Best seller"
                  if (product.isBestSeller)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Best seller',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ------------------ BAGIAN TEKS ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // kategori
                  Text(
                    product.categoryName ?? 'Sneaker',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  const SizedBox(height: 4),

                  // nama produk
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // harga
                  Text(
                    _formatRupiah(product.price),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedImage() {
    // If parent prefetched a resolved signed URL, use it directly.
    final url = resolvedImageUrl;
    final stableKey = product.imageUrl?.split('?').first ?? product.imageUrl;

    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: stableKey,
        fit: BoxFit.cover,
        useOldImageOnUrlChange: true,
        placeholder: (context, _) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: Colors.black38,
          ),
        ),
      );
    }

    // If no resolved URL but imageUrl is already a public/absolute URL, use it.
    final img = product.imageUrl;
    if (img != null && img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        cacheKey: stableKey,
        fit: BoxFit.cover,
        useOldImageOnUrlChange: true,
        placeholder: (context, _) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: Colors.black38,
          ),
        ),
      );
    }

    // Otherwise show a neutral placeholder; resolve may happen later.
    return const Center(
      child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.black38),
    );
  }

  // Helper format "Rp 20.000"
  String _formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final reversedIndex = s.length - i - 1;
      buffer.write(s[reversedIndex]);
      if ((i + 1) % 3 == 0 && i + 1 != s.length) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }
}

// use resolveStorageUrl from core/storage_utils.dart
