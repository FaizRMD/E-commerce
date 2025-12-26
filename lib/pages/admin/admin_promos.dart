import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/supabase_client.dart';
import '../../models/promotion.dart';

String _formatDate(DateTime date) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class AdminPromoScreen extends StatefulWidget {
  const AdminPromoScreen({super.key});

  @override
  State<AdminPromoScreen> createState() => _AdminPromoScreenState();
}

class _AdminPromoScreenState extends State<AdminPromoScreen> {
  List<AppPromotion> _promos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase.from('vouchers').select();
      final promos = (response as List)
          .map((p) => AppPromotion.fromJson(p as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _promos = promos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading promos: $e')));
      }
    }
  }

  Future<void> _deletePromo(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Promo?'),
        content: const Text('Promo ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('vouchers').delete().eq('id', id);
        await _loadPromos();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Promo berhasil dihapus')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleActive(AppPromotion promo) async {
    try {
      await supabase
          .from('vouchers')
          .update({'active': !promo.active})
          .eq('id', promo.id);
      await _loadPromos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promo ${!promo.active ? 'diaktifkan' : 'dinonaktifkan'}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: Text(
          'Kelola Promo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5E3C),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _EditPromoScreen()),
          ).then((_) => _loadPromos());
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promos.isEmpty
          ? Center(
              child: Text(
                'Belum ada promo',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _promos.length,
              itemBuilder: (context, index) {
                final promo = _promos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      promo.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Kode: ${promo.code}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.discountType == 'percentage'
                              ? '${promo.discountValue}% OFF'
                              : 'Rp ${promo.discountValue}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Berlaku: ${_formatDate(promo.validFrom)} - ${_formatDate(promo.validUntil)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Penggunaan: ${promo.usedCount}/${promo.maxUsage == 0 ? "∞" : promo.maxUsage}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _EditPromoScreen(promo: promo),
                              ),
                            ).then((_) => _loadPromos());
                          },
                        ),
                        PopupMenuItem(
                          child: Text(
                            promo.active ? 'Nonaktifkan' : 'Aktifkan',
                          ),
                          onTap: () => _toggleActive(promo),
                        ),
                        PopupMenuItem(
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _deletePromo(promo.id),
                        ),
                      ],
                    ),
                    enabled: true,
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class _EditPromoScreen extends StatefulWidget {
  const _EditPromoScreen({this.promo});

  final AppPromotion? promo;

  @override
  State<_EditPromoScreen> createState() => __EditPromoScreenState();
}

class __EditPromoScreenState extends State<_EditPromoScreen> {
  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _discountValueCtrl;
  late TextEditingController _minPurchaseCtrl;
  late TextEditingController _maxUsageCtrl;

  String _discountType = 'percentage';
  late DateTime _validFrom;
  late DateTime _validUntil;
  bool _active = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final promo = widget.promo;
    _codeCtrl = TextEditingController(text: promo?.code ?? '');
    _titleCtrl = TextEditingController(text: promo?.title ?? '');
    _descriptionCtrl = TextEditingController(text: promo?.description ?? '');
    _discountValueCtrl = TextEditingController(
      text: promo?.discountValue.toString() ?? '',
    );
    _minPurchaseCtrl = TextEditingController(
      text: promo?.minPurchase.toString() ?? '0',
    );
    _maxUsageCtrl = TextEditingController(
      text: promo?.maxUsage.toString() ?? '0',
    );
    _discountType = promo?.discountType ?? 'percentage';
    _validFrom = promo?.validFrom ?? DateTime.now();
    _validUntil =
        promo?.validUntil ?? DateTime.now().add(const Duration(days: 30));
    _active = promo?.active ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _discountValueCtrl.dispose();
    _minPurchaseCtrl.dispose();
    _maxUsageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPromo() async {
    if (_codeCtrl.text.isEmpty ||
        _titleCtrl.text.isEmpty ||
        _discountValueCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'code': _codeCtrl.text.trim().toUpperCase(),
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'discount_type': _discountType,
        'discount_value': int.parse(_discountValueCtrl.text),
        'min_purchase': int.parse(_minPurchaseCtrl.text),
        'max_usage': int.parse(_maxUsageCtrl.text),
        'valid_from': _validFrom.toIso8601String(),
        'valid_until': _validUntil.toIso8601String(),
        'active': _active,
      };

      if (widget.promo != null) {
        // Update
        await supabase
            .from('vouchers')
            .update(payload)
            .eq('id', widget.promo!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo berhasil diperbarui')),
        );
      } else {
        // Create
        await supabase.from('vouchers').insert(payload);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Promo berhasil dibuat')));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validUntil,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isFrom) {
          _validFrom = date;
        } else {
          _validUntil = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: Text(
          widget.promo == null ? 'Tambah Promo' : 'Edit Promo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: 'Kode Promo',
                hintText: 'PROMO2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Promo',
                hintText: 'Diskon Akhir Tahun',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Hemat hingga 50% untuk pembelian...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(label: Text('Persen'), value: 'percentage'),
                      ButtonSegment(label: Text('Rupiah'), value: 'fixed'),
                    ],
                    selected: {_discountType},
                    onSelectionChanged: (value) {
                      setState(() => _discountType = value.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discountValueCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    'Nilai Diskon (${_discountType == 'percentage' ? '%' : 'Rp'})',
                hintText: '10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minPurchaseCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minimal Pembelian (Rp)',
                hintText: '50000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxUsageCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maksimal Penggunaan (0 = unlimited)',
                hintText: '100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Mulai',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_validFrom),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Berakhir',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_validUntil),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Aktif'),
                    value: _active,
                    onChanged: (value) {
                      setState(() => _active = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.promo == null ? 'Buat Promo' : 'Simpan Promo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
