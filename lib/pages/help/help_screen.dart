import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<_FAQItem> _faqList = [
    const _FAQItem(
      question: 'Bagaimana cara melakukan pemesanan?',
      answer:
          'Cukup pilih produk yang Anda inginkan, masukkan jumlah, lalu klik "Beli Sekarang". Ikuti proses checkout dan pilih metode pembayaran.',
    ),
    const _FAQItem(
      question: 'Berapa lama pengiriman?',
      answer:
          'Pengiriman biasanya memakan waktu 2-5 hari kerja tergantung lokasi Anda. Anda dapat melacak pesanan di menu "Pesanan Saya".',
    ),
    const _FAQItem(
      question: 'Apakah ada gratis ongkir?',
      answer:
          'Gratis ongkir berlaku untuk pembelian minimal Rp 100.000. Lihat juga bagian "Voucher & Promo" untuk penawaran terbaru.',
    ),
    const _FAQItem(
      question: 'Bagaimana cara mengembalikan barang?',
      answer:
          'Jika ada masalah dengan produk, hubungi kami dalam 7 hari setelah penerimaan. Kami akan membantu proses pengembalian.',
    ),
    const _FAQItem(
      question: 'Metode pembayaran apa yang tersedia?',
      answer:
          'Kami menerima transfer bank, e-wallet (GCash, Gopay, OVO), dan cicilan kartu kredit melalui platform pembayaran terpercaya.',
    ),
    const _FAQItem(
      question: 'Bagaimana jika saya lupa password?',
      answer:
          'Klik "Lupa Password" di halaman login. Kami akan mengirim link reset ke email terdaftar Anda.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bantuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact info section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hubungi Kami',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'support@tokoonline.com',
                    ),
                    const SizedBox(height: 10),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      title: 'Telepon',
                      value: '+62 812-3456-7890',
                    ),
                    const SizedBox(height: 10),
                    _buildContactItem(
                      icon: Icons.access_time_outlined,
                      title: 'Jam Operasional',
                      value: 'Senin - Jumat: 09:00 - 18:00 WIB',
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 24),

            // FAQ section
            Text(
              'Pertanyaan Umum (FAQ)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqList.length,
              itemBuilder: (context, index) {
                return _FAQExpansionTile(
                  faqItem: _faqList[index],
                  delay: (index * 100).ms,
                );
              },
            ),

            const SizedBox(height: 24),

            // App info
            Center(
              child: Column(
                children: [
                  Text(
                    'Toko Online',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2024 Toko Online. Semua hak dilindungi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B5E3C)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});
}

class _FAQExpansionTile extends StatefulWidget {
  final _FAQItem faqItem;
  final Duration delay;

  const _FAQExpansionTile({required this.faqItem, required this.delay});

  @override
  State<_FAQExpansionTile> createState() => _FAQExpansionTileState();
}

class _FAQExpansionTileState extends State<_FAQExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          widget.faqItem.question,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        collapsedIconColor: const Color(0xFF8B5E3C),
        iconColor: const Color(0xFF8B5E3C),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.faqItem.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: widget.delay).fadeIn().slideY(begin: 0.1);
  }
}
