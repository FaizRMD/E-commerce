import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_client.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vouchers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await supabase
          .from('vouchers')
          .select()
          .eq('is_active', true)
          .order('discount_percent', ascending: false);

      if (mounted) {
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(response as List);
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

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kode promo disalin ke clipboard'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voucher & Promo',
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
          : _vouchers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak Ada Promo',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kembali lagi nanti untuk penawaran terbaru',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                final voucher = _vouchers[index];
                final code = voucher['code'] as String? ?? 'N/A';
                final discount = voucher['discount_percent'] as int? ?? 0;
                final description =
                    voucher['description'] as String? ?? 'Diskon menarik';
                final minPurchase = voucher['min_purchase'] as int? ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5E3C).withOpacity(0.1),
                        const Color(0xFF8B5E3C).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF8B5E3C).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Discount badge and title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5E3C),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Diskon $discount%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              code,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8B5E3C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F2933),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Min purchase
                        if (minPurchase > 0)
                          Text(
                            'Min. pembelian: Rp ${minPurchase.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Copy button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyPromoCode(code),
                            icon: const Icon(Icons.content_copy),
                            label: const Text('Salin Kode'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5E3C),
                              side: const BorderSide(color: Color(0xFF8B5E3C)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
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
