// lib/pages/product/details_screen.dart
import 'package:flutter/material.dart';

import '../../core/ui_constants.dart';
import '../../core/supabase_client.dart';
import '../../models/product.dart';
import '../../core/cart_manager.dart' as cart;
import '../cart/cart_screen.dart';

/// Halaman detail produk.
/// Responsive untuk mobile & web (lebar max dibatasi).
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.product});

  final AppProduct product;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 900 ? 900.0 : size.width;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined, color: kTextColor),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                // KARTU PUTIH BAGIAN BAWAH
                Container(
                  margin: EdgeInsets.only(top: size.height * 0.36),
                  padding: EdgeInsets.only(
                    top: size.height * 0.12,
                    left: kDefaultPadding,
                    right: kDefaultPadding,
                    bottom: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ColorAndSize(product: product),
                      const SizedBox(height: 12),
                      _Description(product: product),
                      const SizedBox(height: 16),
                      _CounterWithFavBtn(product: product),
                      const SizedBox(height: 20),
                      _AddToCartAndBuyNow(product: product),
                    ],
                  ),
                ),

                // BAGIAN ATAS: TITLE + GAMBAR BESAR
                _ProductTitleWithImage(product: product),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bagian judul, harga, rating dan gambar produk.
class _ProductTitleWithImage extends StatelessWidget {
  const _ProductTitleWithImage({required this.product});

  final AppProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.categoryName ?? 'Sneaker',
            style: const TextStyle(color: kTextLightColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(product.price),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFB923C),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                (product.rating ?? 5.0).toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text(
                '(${product.ratingCount ?? 4} reviews)',
                style: const TextStyle(fontSize: 11, color: kTextLightColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Hero(
              tag: 'product_${product.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.directions_run_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian pilihan warna dan size (dummy).
class _ColorAndSize extends StatelessWidget {
  const _ColorAndSize({required this.product});

  final AppProduct product;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 12, color: kTextLightColor);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Color', style: labelStyle),
              SizedBox(height: 8),
              Row(
                children: [
                  _ColorDot(color: Color(0xFF111827), isSelected: true),
                  _ColorDot(color: Color(0xFF6B7280)),
                  _ColorDot(color: Color(0xFFF97316)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Size', style: labelStyle),
              SizedBox(height: 8),
              Text(
                'EU 42',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.isSelected = false});

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? color : Colors.transparent),
      ),
      child: CircleAvatar(radius: 7, backgroundColor: color),
    );
  }
}

/// Deskripsi produk.
class _Description extends StatelessWidget {
  const _Description({required this.product});

  final AppProduct product;

  @override
  Widget build(BuildContext context) {
    final text =
        product.description ??
        'Sneaker nyaman dengan material berkualitas untuk aktivitas harianmu.';

    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF6B7280),
        height: 1.4,
      ),
    );
  }
}

/// Counter jumlah item + tombol favorit yang simpan ke Supabase wishlist.
class _CounterWithFavBtn extends StatefulWidget {
  const _CounterWithFavBtn({required this.product});

  final AppProduct product;

  @override
  State<_CounterWithFavBtn> createState() => _CounterWithFavBtnState();
}

class _CounterWithFavBtnState extends State<_CounterWithFavBtn> {
  int _numOfItems = 1;
  bool _isFav = false;
  bool _isLoadingFav = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
  }

  Future<void> _checkIfInWishlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final result = await supabase
          .from('wishlist')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.product.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFav = result != null;
        });
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _toggleWishlist() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoadingFav = true);

    try {
      if (_isFav) {
        // Hapus dari wishlist
        await supabase
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.product.id);

        if (mounted) {
          setState(() => _isFav = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dihapus dari wishlist')),
          );
        }
      } else {
        // Tambah ke wishlist
        await supabase.from('wishlist').insert({
          'user_id': user.id,
          'product_id': widget.product.id,
        });

        if (mounted) {
          setState(() => _isFav = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke wishlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFav = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_numOfItems > 1) {
                    setState(() => _numOfItems--);
                  }
                },
                color: kTextColor,
              ),
              Text(
                '$_numOfItems',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() => _numOfItems++);
                },
                color: kTextColor,
              ),
            ],
          ),
        ),
        const Spacer(),
        _isLoadingFav
            ? SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey.shade400),
                    ),
                  ),
                ),
              )
            : IconButton(
                onPressed: _toggleWishlist,
                icon: Icon(
                  _isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFav ? Colors.redAccent : Colors.grey.shade400,
                ),
              ),
      ],
    );
  }
}

/// Baris bawah: icon cart, tombol Add to cart, tombol Buy now.
/// Menggunakan CartManager (keranjang tersimpan di Supabase).
class _AddToCartAndBuyNow extends StatelessWidget {
  const _AddToCartAndBuyNow({required this.product});

  final AppProduct product;

  Future<void> _handleAddToCart(BuildContext context) async {
    final cm = cart.CartManager.instance;
    try {
      await cm.addProduct(product, qty: 1);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ditambahkan ke keranjang')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
      );
    }
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    final cm = cart.CartManager.instance;
    try {
      await cm.addProduct(product, qty: 1);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
      await cm.initFromServer(); // refresh badge setelah kembali
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _handleAddToCart(context),
          icon: const Icon(Icons.shopping_cart_outlined, color: kTextColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextColor,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _handleAddToCart(context),
              child: const Text(
                'Add to cart',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTextColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _handleBuyNow(context),
              child: const Text(
                'Buy now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper format harga ke Rp 1.000.000
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
