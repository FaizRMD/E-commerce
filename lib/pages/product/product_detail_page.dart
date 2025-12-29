import 'package:flutter/material.dart';
import '../../widgets/cached_resolved_image.dart';

/// Halaman detail produk untuk e-commerce.
///
/// Menerima sebuah object [product] (biasanya instance `AppProduct` dari home.dart)
/// yang diharapkan punya properti:
/// - `name` (String)
/// - `price` (int)
/// - `imageUrl` (String? / nullable)
/// - `categoryName` (String? / nullable)
/// - `description` (String? / nullable)
///
/// Catatan keamanan:
/// - Halaman ini hanya menampilkan data publik produk (nama, harga, gambar).
/// - Jangan taruh data sensitif (misalnya secret key, token, dsb) di sini.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  /// Object produk yang akan ditampilkan.
  ///
  /// Tipe dibuat `dynamic` supaya bisa menerima model dari file lain
  /// tanpa perlu import dan menghindari circular import.
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    // Helper getter kecil biar aman dari null
    String getString(dynamic value) => value == null ? '' : value.toString();

    final String name = getString(product.name);
    final String categoryName = getString(product.categoryName);
    final String? imageUrl =
        (product.imageUrl is String && product.imageUrl.isNotEmpty)
        ? product.imageUrl as String
        : null;
    final String? description =
        (product.description is String && product.description.isNotEmpty)
        ? product.description as String
        : null;
    final int price = (product.price is int)
        ? product.price as int
        : int.tryParse(getString(product.price)) ?? 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(name, style: const TextStyle(fontSize: 16)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===================== FOTO BESAR =====================
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: imageUrl != null
                  ? CachedResolvedImage(
                      imageUrl,
                      fit: BoxFit.cover,
                      placeholder: Container(color: primary.withOpacity(0.05)),
                      errorWidget: Container(
                        color: primary.withOpacity(0.1),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          size: 80,
                          color: primary,
                        ),
                      ),
                    )
                  : Container(
                      color: primary.withOpacity(0.1),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        size: 80,
                        color: primary,
                      ),
                    ),
            ),
          ),

          // ===================== DETAIL SCROLL =====================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama + Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp $price',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (categoryName.isNotEmpty)
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Rating dummy (bisa diganti data beneran kalau ada tabel review)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(120 reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Color (contoh statis)
                  const Text(
                    'Color',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      _ColorDot(color: Colors.blue, isSelected: true),
                      _ColorDot(color: Colors.black87),
                      _ColorDot(color: Colors.redAccent),
                      _ColorDot(color: Colors.brown),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Size (contoh statis)
                  const Text(
                    'Size',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [
                      _SizeChip(label: 'S'),
                      _SizeChip(label: 'M', isSelected: true),
                      _SizeChip(label: 'L'),
                      _SizeChip(label: 'XL'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Deskripsi
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description ?? 'No description for this product yet.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===================== BOTTOM BAR =====================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: panggil fungsi tambah ke keranjang
                      // Perhatikan keamanan: operasi cart & order
                      // harus dilindungi policy RLS di Supabase.
                      Navigator.pop(context); // sementara balik dulu
                    },
                    child: const Text('ADD TO CART'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // TODO: langsung ke proses checkout
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('BUY NOW'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Titik warna kecil untuk pilihan color.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.isSelected = false});

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade400,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CircleAvatar(radius: 10, backgroundColor: color),
    );
  }
}

/// Chip ukuran (S, M, L, XL).
///
/// Untuk sekarang belum punya state pilihan.
/// Nanti kalau sudah ada tabel variant / stock,
/// bisa dihubungkan ke data Supabase.
class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, this.isSelected = false});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected ? colorScheme.primary : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) {
        // TODO: tambahkan state kalau mau benar-benar memilih size.
      },
    );
  }
}
