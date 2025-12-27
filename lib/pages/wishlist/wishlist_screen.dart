import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_client.dart';
import '../../core/storage_utils.dart';
import '../../widgets/cached_resolved_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<AppProduct> _wishlistProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Anda harus login terlebih dahulu';
            _isLoading = false;
          });
        }
        return;
      }

      // Ambil semua wishlist items user dari tabel wishlist
      final wishlistItems = await supabase
          .from('wishlist')
          .select('product_id')
          .eq('user_id', user.id);

      if (wishlistItems.isEmpty) {
        if (mounted) {
          setState(() {
            _wishlistProducts = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Extract product IDs
      final productIds = (wishlistItems as List)
          .map((item) => item['product_id'] as int)
          .toList();

      // Ambil detail produk
      final products = await supabase
          .from('products')
          .select('*, categories(name)')
          .inFilter('id', productIds);

      if (mounted) {
        setState(() {
          _wishlistProducts = (products as List)
              .map((p) => AppProduct.fromJoinedMap(p as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist(int productId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('wishlist')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      if (mounted) {
        setState(() {
          _wishlistProducts.removeWhere((product) => product.id == productId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dihapus dari wishlist')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wishlist Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : _wishlistProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wishlist Kosong',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan produk favorit Anda',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _wishlistProducts.length,
              itemBuilder: (context, index) {
                final product = _wishlistProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: product.imageUrl != null
                                ? CachedResolvedImage(
                                    product.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      color: Colors.grey.shade200,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.categoryName ?? 'Kategori',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8B5E3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Remove button
                        IconButton(
                          onPressed: () => _removeFromWishlist(product.id),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1);
              },
            ),
    );
  }
}
