// lib/pages/cart/cart_screen.dart
import 'package:flutter/material.dart';

import '../../core/cart_manager.dart';
import '../../core/ui_constants.dart';
import '../../widgets/cached_resolved_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartManager _cart = CartManager.instance;
  final Set<int> _selectedIds = {};
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  Future<void> _refreshCart() async {
    await _cart.initFromServer();
    setState(() {
      _selectedIds.clear();
    });
  }

  int get _selectedSubtotal {
    return _cart.items
        .where((item) => _selectedIds.contains(item.id))
        .fold<int>(0, (sum, item) => sum + item.lineTotal);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          if (_cart.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshCart,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Keranjangmu masih kosong')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshCart,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _cart.items[index];
                final bool selected = _selectedIds.contains(item.id);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(item.id);
                            } else {
                              _selectedIds.remove(item.id);
                            }
                          });
                        },
                      ),
                      // gambar produk
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xFFE5E7EB),
                          child:
                              item.productImageUrl != null &&
                                  item.productImageUrl!.isNotEmpty
                              ? CachedResolvedImage(
                                  item.productImageUrl,
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                  placeholder: const SizedBox(),
                                  errorWidget: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // nama + qty
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(item.unitPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final newQty = item.quantity - 1;
                                    await _cart.updateQty(item.id, newQty);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: kTextColor,
                                  iconSize: 20,
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final newQty = item.quantity + 1;
                                    await _cart.updateQty(item.id, newQty);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: kTextColor,
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _cart.removeItem(item.id);
                          setState(() {
                            _selectedIds.remove(item.id);
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          if (_cart.items.isEmpty) {
            return const SizedBox.shrink();
          }

          final int subtotal = _selectedSubtotal;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Subtotal (${_selectedIds.length} item)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatRupiah(subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cart.items.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    if (_selectedIds.length ==
                                        _cart.items.length) {
                                      _selectedIds.clear();
                                    } else {
                                      _selectedIds
                                        ..clear()
                                        ..addAll(_cart.items.map((e) => e.id));
                                    }
                                  });
                                },
                          child: Text(
                            _selectedIds.length == _cart.items.length
                                ? 'Batal pilih semua'
                                : 'Pilih semua',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedIds.isEmpty || _isCheckingOut
                              ? null
                              : () async {
                                  setState(() {
                                    _isCheckingOut = true;
                                  });

                                  try {
                                    await _cart.checkoutSelected(
                                      _selectedIds.toList(),
                                    );

                                    if (!mounted) return;

                                    setState(() {
                                      _selectedIds.clear();
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Checkout berhasil dibuat',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal checkout: $e'),
                                      ),
                                    );
                                  } finally {
                                    if (!mounted) return;
                                    setState(() {
                                      _isCheckingOut = false;
                                    });
                                  }
                                },
                          child: _isCheckingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Checkout yang dipilih'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
