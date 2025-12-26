import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui_constants.dart';
import '../../core/cart_state.dart';
import '../../core/supabase_client.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../promo/promo_list_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.product,
    this.initialQty = 1,
    this.initialName,
    this.initialPhone,
    this.initialAddress,
  });

  final AppProduct product;
  final int initialQty;
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();

  String _paymentMethod = 'cash'; // cash / transfer / ewallet
  bool _isSubmitting = false;
  late int _qty;
  AppPromotion? _selectedPromo;
  int _promoDiscount = 0;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameCtrl.text =
          (user.userMetadata?['full_name'] as String?) ?? user.email ?? '';
    }
    // Prefill dari Quick Buy (jika ada)
    if ((widget.initialName ?? '').isNotEmpty) {
      _nameCtrl.text = widget.initialName!;
    }
    if ((widget.initialPhone ?? '').isNotEmpty) {
      _phoneCtrl.text = widget.initialPhone!;
    }
    if ((widget.initialAddress ?? '').isNotEmpty) {
      _addressCtrl.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  int get _subtotal => widget.product.price * _qty;
  int get _shipping => 0; // bisa diganti 10000 kalau mau ongkir
  int get _total => _subtotal + _shipping - _promoDiscount;

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

      // 1) Insert ke orders. Coba dengan kolom shipping_*
      Map<String, dynamic> orderPayload = {
        'user_id': user.id,
        'user_name': userName,
        'customer_name': _nameCtrl.text.trim(),
        'total': _subtotal,
        'total_amount': _total,
        'status': 'pending',
        'payment_method': _paymentMethod,
        // tetap isi note sebagai fallback/riwayat singkat
        'note':
            'Telp: ${_phoneCtrl.text.trim()}\nAlamat: ${_addressCtrl.text.trim()}',
        // kolom baru (akan diabaikan jika belum dibuat; fallback di-catch)
        'shipping_name': _nameCtrl.text.trim(),
        'shipping_phone': _phoneCtrl.text.trim(),
        'shipping_address': _addressCtrl.text.trim(),
      };

      Map<String, dynamic> insertedOrder;
      try {
        insertedOrder = await supabase
            .from('orders')
            .insert(orderPayload)
            .select('id')
            .single();
      } on PostgrestException catch (_) {
        // Jika kolom shipping_* belum ada (belum migrasi), kirim payload minimal.
        final fallbackPayload = Map<String, dynamic>.from(orderPayload)
          ..remove('shipping_name')
          ..remove('shipping_phone')
          ..remove('shipping_address');
        insertedOrder = await supabase
            .from('orders')
            .insert(fallbackPayload)
            .select('id')
            .single();
      }

      final String orderId = insertedOrder['id'] as String;

      // 2) insert ke order_items
      await supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': widget.product.id,
        'qty': _qty,
        'price': widget.product.price,
        'subtotal': _subtotal,
      });

      // 3) Track voucher usage if promo was applied
      if (_selectedPromo != null) {
        // Insert voucher redemption record
        await supabase.from('voucher_redemptions').insert({
          'voucher_id': _selectedPromo!.id,
          'user_id': user.id,
          'order_id': orderId,
          'discount_amount': _promoDiscount,
        });

        // Increment used_count for the voucher
        await supabase
            .from('vouchers')
            .update({'used_count': _selectedPromo!.usedCount + 1})
            .eq('id', _selectedPromo!.id);
      }

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

  Future<void> _applyPromoCode() async {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan kode promo')));
      return;
    }

    try {
      final response = await supabase
          .from('vouchers')
          .select()
          .eq('code', code)
          .eq('active', true)
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kode promo tidak valid')));
        return;
      }

      final promo = AppPromotion.fromJson(response as Map<String, dynamic>);

      if (!promo.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Promo sudah kadaluarsa atau mencapai batas penggunaan',
            ),
          ),
        );
        return;
      }

      if (_subtotal < promo.minPurchase) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Minimal pembelian Rp ${promo.minPurchase} untuk promo ini',
            ),
          ),
        );
        return;
      }

      setState(() {
        _selectedPromo = promo;
        _promoDiscount = promo.calculateDiscount(_subtotal);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promo diterapkan! Diskon Rp ${_formatRupiah(_promoDiscount)}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses promo: $e')));
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

                    // promo code
                    const Text(
                      'Voucher & Promo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Masukkan kode promo',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Terapkan'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final selected = await Navigator.push<AppPromotion>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PromoListScreen(
                                  onPromoSelected: (promo) {
                                    _promoCtrl.text = promo.code;
                                  },
                                ),
                              ),
                            );
                            if (selected != null && mounted) {
                              _applyPromoCode();
                            }
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    if (_selectedPromo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedPromo!.title} diterapkan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Diskon: Rp ${_formatRupiah(_promoDiscount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPromo = null;
                                  _promoDiscount = 0;
                                  _promoCtrl.clear();
                                });
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.green.shade600,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                            if (_promoDiscount > 0) ...[
                              const SizedBox(height: 4),
                              _rowPrice(
                                'Diskon',
                                -_promoDiscount,
                                color: Colors.green,
                              ),
                            ],
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

  Widget _rowPrice(
    String label,
    int value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          _formatRupiah(value),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color,
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
