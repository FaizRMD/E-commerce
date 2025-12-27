// lib/pages/product/details_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/ui_constants.dart';
import '../../core/supabase_client.dart';
import '../../models/product.dart';
import '../../core/storage_utils.dart';
import '../../widgets/cached_resolved_image.dart';
import '../../core/cart_manager.dart' as cart;
import '../checkout/checkout_screen.dart';

/// Halaman detail produk.
/// Responsive untuk mobile & web (lebar max dibatasi).
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.product});

  final AppProduct product;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  int _qty = 1;
  late final AnimationController _controller;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // Jalankan animasi setelah frame pertama dirender agar halus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                // Bottom white card
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: Container(
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
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ColorAndSize(product: widget.product),
                          const SizedBox(height: 12),
                          _Description(product: widget.product),
                          const SizedBox(height: 16),
                          _CounterWithFavBtn(
                            product: widget.product,
                            initialQty: _qty,
                            onQtyChanged: (value) {
                              setState(() => _qty = value);
                            },
                          ),
                          const SizedBox(height: 20),
                          _AddToCartAndBuyNow(
                            product: widget.product,
                            qty: _qty,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top title + image
                _ProductTitleWithImage(product: widget.product),
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
                      ? CachedResolvedImage(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: const Center(child: CircularProgressIndicator()),
                          errorWidget: const Center(
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
  const _CounterWithFavBtn({
    required this.product,
    required this.initialQty,
    required this.onQtyChanged,
  });

  final AppProduct product;
  final int initialQty;
  final ValueChanged<int> onQtyChanged;

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
    _numOfItems = widget.initialQty;
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
                    widget.onQtyChanged(_numOfItems);
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
                  widget.onQtyChanged(_numOfItems);
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
  const _AddToCartAndBuyNow({required this.product, required this.qty});

  final AppProduct product;
  final int qty;

  Future<void> _handleAddToCart(BuildContext context) async {
    final cm = cart.CartManager.instance;
    try {
      await cm.addProduct(product, qty: qty);
      if (!context.mounted) return;
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
    try {
      final result = await showModalBottomSheet<_QuickBuyResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _QuickBuySheet(product: product, qty: qty);
        },
      );

      if (result == null) return;
      if (!context.mounted) return;
      // Lanjutkan ke halaman Checkout dengan nilai prefilled
      // agar user bisa review sebelum membuat pesanan.
      // (Semua logic DB tetap terpusat di CheckoutScreen.)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            product: product,
            initialQty: qty,
            initialName: result.name,
            initialPhone: result.phone,
            initialAddress: result.address,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memproses: $e')));
      }
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

// ========================= QUICK BUY SHEET =========================

class _QuickBuyResult {
  final String name;
  final String phone;
  final String address;
  const _QuickBuyResult({
    required this.name,
    required this.phone,
    required this.address,
  });
}

class _QuickBuySheet extends StatefulWidget {
  const _QuickBuySheet({required this.product, required this.qty});

  final AppProduct product;
  final int qty;

  @override
  State<_QuickBuySheet> createState() => _QuickBuySheetState();
}

class _QuickBuySheetState extends State<_QuickBuySheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null) {
      _nameCtrl.text =
          (user.userMetadata?['full_name'] as String?) ?? user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child:
                              widget.product.imageUrl != null &&
                                  widget.product.imageUrl!.isNotEmpty
                              ? CachedResolvedImage(
                                  widget.product.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      Container(color: Colors.grey.shade200),
                                  errorWidget: Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_outlined),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_outlined),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatRupiah(widget.product.price)}  •  Qty ${widget.qty}',
                              style: const TextStyle(color: kTextLightColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alamat Pengiriman (Cepat)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama penerima',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addrCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat lengkap',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTextColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (_nameCtrl.text.trim().isEmpty ||
                            _phoneCtrl.text.trim().isEmpty ||
                            _addrCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lengkapi nama, no HP, dan alamat'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(
                          context,
                          _QuickBuyResult(
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            address: _addrCtrl.text.trim(),
                          ),
                        );
                      },
                      child: const Text('Lanjutkan ke Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
