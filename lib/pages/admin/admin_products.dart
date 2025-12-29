import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
// debugPrint not required here; use print or ScaffoldMessenger for user-visible logs

import '../../core/supabase_client.dart';
import '../../widgets/cached_resolved_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<AppProduct> _products = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('products')
          .select('*, categories(name)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _products = (data as List)
              .map((json) => AppProduct.fromMap(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<AppProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      // Fetch product to get image URL (if any)
      final productData = await supabase
          .from('products')
          .select('id, image_url')
          .eq('id', productId)
          .maybeSingle();
      String? imageUrl;
      if (productData != null) {
        final pd = Map<String, dynamic>.from(productData as Map);
        imageUrl = pd['image_url'] as String?;
      }

      // If there's an image, try to delete the storage object first
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Determine file path inside bucket.
          String? filePath;
          final marker = 'product-images/';
          if (imageUrl.contains(marker)) {
            final idx = imageUrl.indexOf(marker);
            filePath = imageUrl.substring(idx + marker.length);
          } else if (imageUrl.startsWith('http')) {
            // Could be a full public URL lacking an obvious marker; can't reliably delete.
            filePath = null;
          } else {
            // Treat stored value as internal path already
            filePath = imageUrl;
          }

          if (filePath != null && filePath.isNotEmpty) {
            await supabase.storage.from('product-images').remove([filePath]);
          }
        } catch (e) {
          // Log but continue to delete DB record
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: failed to delete image file: $e'),
              ),
            );
          }
        }
      }

      // Delete DB record
      await supabase.from('products').delete().eq('id', productId);
      // If deletion succeeded, remove locally so UI updates immediately
      if (mounted) {
        setState(() {
          _products.removeWhere((p) => p.id == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        // Refresh from server in background to ensure state consistency
        _loadProducts();
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
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _ProductCard(
                          product: product,
                          onEdit: () => _showProductForm(product),
                          onDelete: () => _confirmDelete(product),
                        ).animate().fadeIn(delay: (50 * index).ms).slideX();
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(null),
        backgroundColor: const Color(0xFF8B5E3C),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showProductForm(AppProduct? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ProductFormSheet(product: product, onSaved: _loadProducts),
    );
  }

  Future<void> _confirmDelete(AppProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteProduct(product.id);
    }
  }
}

class _ProductCard extends StatelessWidget {
  final AppProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _ProductImage(imageUrl: product.imageUrl),
        ),
        title: Text(
          product.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatPrice(product.price)}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B5E3C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (product.categoryName != null)
              Text(
                product.categoryName!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  final AppProduct? product;
  final VoidCallback onSaved;

  const _ProductFormSheet({this.product, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _isBestSeller = false;
  bool _isSubmitting = false;
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];

  Uint8List? _selectedImageBytes;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _imageUrl = widget.product!.imageUrl;
      _isActive = widget.product!.isActive;
      _isBestSeller = widget.product!.isBestSeller;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickFromAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final assetKeys =
          manifestMap.keys.where((k) => k.startsWith('assets/images/')).toList()
            ..sort();

      if (assetKeys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada asset di assets/images')),
          );
        }
        return;
      }

      final chosen = await showDialog<String?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Pilih gambar dari assets'),
          children: assetKeys.map((p) {
            final name = p.split('/').last;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, p),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.asset(p, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name)),
                ],
              ),
            );
          }).toList(),
        ),
      );

      if (chosen != null) {
        final bytes = (await rootBundle.load(chosen)).buffer.asUint8List();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membaca asset: $e')));
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return _imageUrl;

    // Pastikan user terautentikasi sebelum mencoba upload
    final user = supabase.auth.currentUser;
    if (user == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Belum login'),
          content: const Text(
            'Anda harus login untuk mengupload gambar. Lanjut tanpa gambar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjut tanpa gambar'),
            ),
          ],
        ),
      );

      if (proceed != true) return null;
      return null;
    }

    final fileName =
        'products/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.trim()}.jpg';

    int attempts = 0;
    while (attempts < 3) {
      try {
        await supabase.storage
            .from('product-images')
            .uploadBinary(
              fileName,
              _selectedImageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        // Return storage path (inside bucket). Store this in DB, not a full public URL.
        print('uploaded file to: $fileName');
        return fileName;
      } catch (e) {
        attempts++;
        if (!mounted) return null;

        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error uploading image'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Lanjut tanpa gambar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

        if (retry != true) {
          // User chose to continue without image
          return null;
        }
        // else loop to retry
      }
    }

    return null;
  }

  Future<void> _loadCategories() async {
    try {
      final data = await supabase.from('categories').select('id, name');
      if (mounted) {
        setState(() => _categories = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload image dan dapatkan URL
      final uploadedImageUrl = await _uploadImage();
      print(
        'uploadedImageUrl (storage path): $uploadedImageUrl, existing imageUrl: $_imageUrl',
      );

      if (_selectedImageBytes != null && uploadedImageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal upload gambar — produk akan dibuat tanpa gambar',
              ),
            ),
          );
        }
        // Note: do not return here; continue to create product without the new image.
      }

      final data = {
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'image_url': uploadedImageUrl ?? _imageUrl,
        'is_active': _isActive,
        'is_best_seller': _isBestSeller,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
      };

      if (widget.product == null) {
        // Create new product
        final res = await supabase.from('products').insert(data);
        print('insert response: $res');
      } else {
        // Update existing product
        final res = await supabase
            .from('products')
            .update(data)
            .eq('id', widget.product!.id);
        print('update response: $res');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Produk berhasil dibuat'
                  : 'Produk berhasil diperbarui',
            ),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Price is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Produk',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Preview atau Placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: _selectedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              cacheKey:
                                  _imageUrl?.split('?').first ?? _imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, _) => const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, _, __) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gambar tidak bisa dimuat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada gambar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Button untuk pick image
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _selectedImageBytes != null
                          ? 'Ganti Gambar'
                          : 'Pilih Gambar dari Galeri',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickFromAssets,
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      'Pilih dari folder assets',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gambar baru akan diupload saat disimpan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'] as int,
                    child: Text(cat['name'] as String),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Aktif'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),

              SwitchListTile(
                title: const Text('Best Seller'),
                value: _isBestSeller,
                onChanged: (val) => setState(() => _isBestSeller = val),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _isSubmitting ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.product == null
                            ? 'Buat Produk'
                            : 'Update Produk',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  const _ProductImage({this.imageUrl});
  // Uses centralized resolver with caching to avoid frequent signed-URL requests.
  // The actual resolution is done by `resolveStorageUrl` in `lib/core/storage_utils.dart`.

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.image),
      );
    }

    return CachedResolvedImage(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}
