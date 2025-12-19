import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;
  ProfileModel? _profile;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Gunakan maybeSingle() untuk menghindari error PGRST116
      var data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Jika profil belum ada, buat row baru
      if (data == null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'role': 'user',
        });

        // Ambil lagi setelah insert
        data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      }

      if (data == null) {
        throw Exception('Gagal memuat profil');
      }

      final profile = ProfileModel.fromMap(data);

      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = profile.fullName ?? '';
          _phoneController.text = profile.phone ?? '';
          _addressController.text = profile.address ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    if (_pickedFile == null || _profile == null) return;

    setState(() => _isUploading = true);
    try {
      final user = supabase.auth.currentUser!;
      final fileExt = _pickedFile!.name.split('.').last;
      final fileName = '${user.id}/avatar.${fileExt.toLowerCase()}';

      // Upload dengan upsert untuk menghindari duplicate file error
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            await _pickedFile!.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      final avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _profile = _profile!.copyWith(avatarUrl: avatarUrl);
          _isUploading = false;
          _pickedFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar berhasil diupdate')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;

    try {
      await supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          })
          .eq('id', _profile!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar section
                    GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              image: _profile?.avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profile!.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profile?.avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5E3C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOut),

                    const SizedBox(height: 8),
                    Text(
                      'Tap untuk ubah foto',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'No. Telepon',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Alamat Lengkap',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5E3C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Simpan Profil',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5E3C), width: 2),
        ),
      ),
    );
  }
}
