// lib/pages/cart/cart_screen.dart
import 'package:flutter/material.dart';

import '../../core/cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await CartManager.instance.fetchCartItems();
      if (!mounted) return;
      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(
      0,
      (sum, item) => sum + (item['subtotal'] as int),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(_error!)),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Keranjang masih kosong')),
                ],
              )
            : ListView.builder(
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    // baris total + tombol checkout
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                _formatRupiah(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: lanjut ke halaman checkout
                              },
                              child: const Text('Checkout'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final item = _items[index];
                  final name = item['name'] as String;
                  final imageUrl = item['imageUrl'] as String?;
                  final qty = item['qty'] as int;
                  final price = item['price'] as int;
                  final subtotal = item['subtotal'] as int;

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                    title: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('x$qty • ${_formatRupiah(price)}'),
                    trailing: Text(
                      _formatRupiah(subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
      ),
    );
  }
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
