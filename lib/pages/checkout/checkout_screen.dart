import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui_constants.dart';
import '../../core/cart_state.dart';
import '../../models/product.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.product, this.initialQty = 1});

  final AppProduct product;
  final int initialQty;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _paymentMethod = 'cash'; // cash / transfer / ewallet
  bool _isSubmitting = false;
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameCtrl.text =
          (user.userMetadata?['full_name'] as String?) ?? user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  int get _subtotal => widget.product.price * _qty;
  int get _shipping => 0; // bisa diganti 10000 kalau mau ongkir
  int get _total => _subtotal + _shipping;

  Future<void> _submitOrder() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama, no HP, dan alamat')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String userName =
          (user.userMetadata?['full_name'] as String?) ?? user.email ?? 'User';

      // 1) insert ke orders
      final insertedOrder = await supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'user_name': userName,
            'customer_name': _nameCtrl.text.trim(),
            'total': _subtotal,
            'total_amount': _total,
            'status': 'pending',
            'payment_method': _paymentMethod,
            // untuk sekarang alamat+hp disimpan di note
            'note':
                'Telp: ${_phoneCtrl.text.trim()}\nAlamat: ${_addressCtrl.text.trim()}',
          })
          .select('id')
          .single();

      final String orderId = insertedOrder['id'] as String;

      // 2) insert ke order_items
      await supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': widget.product.id,
        'qty': _qty,
        'price': widget.product.price,
        'subtotal': _subtotal,
      });

      // update icon keranjang
      CartState.add(_qty);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            totalAmount: _total,
            product: widget.product,
            qty: _qty,
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi nanti')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ringkasan produk
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 64,
                                width: 64,
                                child:
                                    widget.product.imageUrl != null &&
                                        widget.product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        widget.product.imageUrl!,
                                        fit: BoxFit.cover,
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatRupiah(widget.product.price),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('Qty: '),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                        onPressed: _qty > 1
                                            ? () {
                                                setState(() => _qty--);
                                              }
                                            : null,
                                      ),
                                      Text('$_qty'),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          setState(() => _qty++);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // alamat
                    const Text(
                      'Alamat Pengiriman',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama penerima',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. HP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alamat lengkap',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // metode pembayaran
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'cash',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Transfer bank'),
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('E-wallet'),
                      value: 'ewallet',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),

                    const SizedBox(height: 16),

                    // ringkasan harga
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _rowPrice('Subtotal', _subtotal),
                            const SizedBox(height: 4),
                            _rowPrice('Ongkir', _shipping),
                            const Divider(height: 16),
                            _rowPrice('Total', _total, isBold: true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTextColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitOrder,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Buat pesanan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowPrice(String label, int value, {bool isBold = false}) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          _formatRupiah(value),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
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
