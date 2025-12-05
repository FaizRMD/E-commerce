import 'package:flutter/material.dart';

import '../../core/ui_constants.dart';
import '../../models/product.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.product,
    required this.qty,
  });

  final String orderId;
  final int totalAmount;
  final AppProduct product;
  final int qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pesanan Berhasil',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(Icons.check_rounded, size: 46, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terima kasih!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesananmu sudah kami terima.\nDetail pesanan ada di bawah ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kTextLightColor),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 52,
                              width: 52,
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
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
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: $qty',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Total pembayaran',
                            style: TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            _formatRupiah(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ID pesanan: $orderId',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextLightColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'Kembali ke beranda',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
