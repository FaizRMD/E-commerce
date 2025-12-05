import 'package:flutter/material.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  bool _couponApplied = false;

  double get _originalTotal => 950000;
  double get _discountedTotal => _originalTotal * 0.8; // diskon 20%

  @override
  Widget build(BuildContext context) {
    final primary = Colors.indigo;
    final total = _couponApplied ? _discountedTotal : _originalTotal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          'Promo & Kupon',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // kembali ke Home
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Belanja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3 item dalam keranjang',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatRupiah(total),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _couponApplied ? Colors.green : primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_couponApplied)
                      const Text(
                        'Kupon UTS20 berhasil diterapkan (20% off)',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      )
                    else
                      const Text(
                        'Masukkan kupon untuk mendapatkan diskon.',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kupon Tersedia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: const [
                          Flexible(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UTS20',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Diskon 20% untuk minimal belanja Rp 500.000',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.local_offer_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _couponApplied = !_couponApplied;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _couponApplied
                              ? 'Batalkan Kupon'
                              : 'Terapkan Kupon',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(double value) {
    // Format simpel tanpa package intl
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final hasil = buffer.toString().split('').reversed.join();
    return 'Rp $hasil';
  }
}
