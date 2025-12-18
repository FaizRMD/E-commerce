// lib/pages/home/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/cart_manager.dart';
import '../../core/supabase_client.dart';
import '../../core/ui_constants.dart';
import '../../models/product.dart';
import '../cart/cart_screen.dart';
import '../product/details_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/my_orders_screen.dart';
import '../widgets/categories.dart';
import '../widgets/item_card.dart';

// Palet warna khusus home (senada dengan login coklat)
const Color _primaryBrown = Color(0xFF8B5E3C);
const Color _textDark = Color(0xFF1F2933);
const Color _textLight = Color(0xFF9AA5B1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- loading state ---
  bool _isLoading = true;
  String? _errorMessage;

  // --- data dari Supabase ---
  final List<AppProduct> _allProducts = [];
  List<AppProduct> _visibleProducts = [];
  final List<String> _categoryLabels = ['All'];
  String? _selectedCategoryName = 'All';
  String _searchQuery = '';

  // --- hero slider data ---
  final PageController _heroController = PageController(viewportFraction: 0.9);
  int _currentHero = 0;
  Timer? _heroTimer;

  // cart manager (buat badge dan keranjang)
  final CartManager _cart = CartManager.instance;

  /// Banner simple untuk sneaker store (pakai gambar asset)
  /// PASTIKAN nama file & path cocok dengan pubspec.yaml:
  /// assets:
  ///   - assets/images/banner1.png
  ///   - assets/images/air_max_stret.png
  ///   - assets/images/jordan_clasic.png
  final List<_HeroBannerData> _heroBanners = const [
    _HeroBannerData(
      title: 'Temukan Sneaker\nFavoritmu',
      subtitle: 'Koleksi terbaru untuk gaya harianmu.',
      badge: 'NEW DROP',
      imageAsset: 'assets/images/banner1.png',
      darkOverlay: true,
    ),
    _HeroBannerData(
      title: 'Air Max Street',
      subtitle: 'Ringan dan nyaman untuk aktivitas sehari-hari.',
      badge: 'BEST DEAL',
      imageAsset: 'assets/images/air_max_stret.png',
      darkOverlay: true,
    ),
    _HeroBannerData(
      title: 'Jordan Classic',
      subtitle: 'Look klasik buat pecinta basket.',
      badge: 'HOT',
      imageAsset: 'assets/images/jordan_clasic.png',
      darkOverlay: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startHeroAutoPlay();
    _init();
  }

  Future<void> _init() async {
    await _cart.initFromServer();
    await _loadData();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HERO AUTOPLAY
  // ---------------------------------------------------------------------------
  void _startHeroAutoPlay() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_heroController.hasClients || _heroBanners.isEmpty) return;
      _currentHero = (_currentHero + 1) % _heroBanners.length;
      _heroController.animateToPage(
        _currentHero,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      setState(() {});
    });
  }

  // ---------------------------------------------------------------------------
  // LOAD DATA DARI SUPABASE
  // ---------------------------------------------------------------------------
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([_fetchCategories(), _fetchProducts()]);
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    final response = await supabase
        .from('categories')
        .select('name')
        .order('id');

    final data = response as List<dynamic>;

    _categoryLabels
      ..clear()
      ..add('All')
      ..addAll(
        data
            .map((row) => (row as Map<String, dynamic>)['name'] as String)
            .toList(),
      );
  }

  Future<void> _fetchProducts() async {
    final response = await supabase
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('is_best_seller', ascending: false)
        .order('id', ascending: false);

    final data = response as List<dynamic>;

    _allProducts
      ..clear()
      ..addAll(
        data.map(
          (row) => AppProduct.fromJoinedMap(row as Map<String, dynamic>),
        ),
      );
  }

  void _applyFilter() {
    Iterable<AppProduct> base = _allProducts;

    if (_selectedCategoryName != null && _selectedCategoryName != 'All') {
      base = base.where((p) => p.categoryName == _selectedCategoryName);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      base = base.where((p) => p.name.toLowerCase().contains(query));
    }

    _visibleProducts = base.toList();
  }

  void _onCategorySelected(String label) {
    setState(() {
      _selectedCategoryName = label;
      _applyFilter();
    });
  }

  void _openProfileSheet() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openOrders() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature segera hadir')));
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    await supabase.auth.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));
  }

  void _openSearchSheet() {
    final controller = TextEditingController(text: _searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: _textDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Cari produk, brand, atau kategori',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilter();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilter();
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: _textDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SearchChip(
                    label: 'Air Max',
                    onTap: () => _applySearchSuggestion('Air Max'),
                  ),
                  _SearchChip(
                    label: 'Jordan',
                    onTap: () => _applySearchSuggestion('Jordan'),
                  ),
                  _SearchChip(
                    label: 'Running',
                    onTap: () => _applySearchSuggestion('Running'),
                  ),
                  _SearchChip(
                    label: 'Best seller',
                    onTap: () => _applySearchSuggestion('best'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Hasil: ${_visibleProducts.length} produk',
                style: const TextStyle(fontSize: 12, color: _textLight),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applySearchSuggestion(String keyword) {
    setState(() {
      _searchQuery = keyword;
      _applyFilter();
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        onProfile: _openProfileSheet,
        onOrders: _openOrders,
        onWishlist: () {
          Navigator.pop(context);
          _showComingSoon('Wishlist');
        },
        onVouchers: () {
          Navigator.pop(context);
          _showComingSoon('Voucher & Promo');
        },
        onHelp: () {
          Navigator.pop(context);
          _showComingSoon('Bantuan');
        },
        onLogout: _logout,
      ),
      // background dengan gradasi tipis biar nggak polos
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF5EF), Color(0xFFF3E7DB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _ErrorState(message: _errorMessage!, onRetry: _loadData)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Di web / tablet, konten max 900 biar centrang & rapih
                    final double maxWidth = constraints.maxWidth > 900.0
                        ? 900.0
                        : constraints.maxWidth;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: maxWidth,
                        child: Column(
                          children: [
                            _buildAppBar(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadData,
                                child: CustomScrollView(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: kDefaultPadding,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const _WelcomeHeader()
                                                .animate()
                                                .fadeIn(duration: 400.ms)
                                                .moveY(
                                                  begin: 10,
                                                  duration: 400.ms,
                                                ),
                                            const SizedBox(height: 18),
                                            _HeroCarousel(
                                                  banners: _heroBanners,
                                                  controller: _heroController,
                                                  currentIndex: _currentHero,
                                                  onChanged: (index) {
                                                    setState(() {
                                                      _currentHero = index;
                                                    });
                                                  },
                                                )
                                                .animate()
                                                .fadeIn(
                                                  duration: 400.ms,
                                                  delay: 80.ms,
                                                )
                                                .moveY(begin: 12),
                                            const SizedBox(height: 24),
                                            Categories(
                                              categories: _categoryLabels,
                                              selectedLabel:
                                                  _selectedCategoryName,
                                              onSelected: _onCategorySelected,
                                            ).animate().fadeIn(
                                              duration: 350.ms,
                                            ),
                                            const SizedBox(height: 18),
                                            const _SectionHeader(
                                              title: 'Popular Sneakers',
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // GRID PRODUK
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding,
                                        vertical: 8,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  constraints.maxWidth > 700
                                                  ? 3
                                                  : 2,
                                              mainAxisSpacing: 18,
                                              crossAxisSpacing: 18,
                                              // 0.68 → cell sedikit lebih tinggi,
                                              // menghindari overflow kuning-hitam
                                              childAspectRatio:
                                                  constraints.maxWidth > 700
                                                  ? 0.8
                                                  : 0.68,
                                            ),
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final product =
                                              _visibleProducts[index];
                                          return ItemCard(
                                                product: product,
                                                press: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          DetailsScreen(
                                                            product: product,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              )
                                              .animate()
                                              .fadeIn(
                                                duration: 350.ms,
                                                delay: (index * 40).ms,
                                              )
                                              .scale(
                                                begin: const Offset(0.95, 0.95),
                                                duration: 300.ms,
                                                curve: Curves.easeOutCubic,
                                              );
                                        }, childCount: _visibleProducts.length),
                                      ),
                                    ),
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 32),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // AppBar custom dengan badge cart
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: 4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: _textDark),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Sneakify',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _textDark,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _openSearchSheet,
            icon: const Icon(Icons.search_rounded, color: _textDark),
          ),
          // icon cart + badge
          ValueListenableBuilder<int>(
            valueListenable: _cart.cartCountNotifier,
            builder: (context, count, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                      // setelah balik dari cart, refresh badge dari server
                      await _cart.initFromServer();
                    },
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: _textDark,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB WIDGETS
// ---------------------------------------------------------------------------

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onProfile,
    required this.onOrders,
    required this.onWishlist,
    required this.onVouchers,
    required this.onHelp,
    required this.onLogout,
  });

  final VoidCallback onProfile;
  final VoidCallback onOrders;
  final VoidCallback onWishlist;
  final VoidCallback onVouchers;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _primaryBrown,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Akun Saya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil & Akun'),
              onTap: onProfile,
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Pesanan Saya'),
              onTap: onOrders,
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Wishlist'),
              onTap: onWishlist,
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('Voucher & Promo'),
              onTap: onVouchers,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Bantuan'),
              onTap: onHelp,
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Temukan Sepatu Favoritmu 👟',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Koleksi sneaker terbaru untuk gaya harianmu.',
          style: TextStyle(fontSize: 13, color: _textLight),
        ),
      ],
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.banners,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<_HeroBannerData> banners;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final data = banners[index];
              final bool isActive = index == currentIndex;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isActive ? 1.0 : 0.7,
                  child: _HeroBannerCard(data: data),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentIndex == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: currentIndex == i ? _primaryBrown : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBannerCard extends StatelessWidget {
  const _HeroBannerCard({required this.data});

  final _HeroBannerData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // FOTO FULL CARD
            Positioned.fill(
              child: Image.asset(data.imageAsset, fit: BoxFit.cover),
            ),
            // OVERLAY GRADIENT AGAR TEKS TERBACA
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.darkOverlay
                        ? [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.2),
                          ]
                        : [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.0),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // KONTEN TEKS + BUTTON
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        data.badge.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB923C),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Shop now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          'See all',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _HeroBannerData {
  final String title;
  final String subtitle;
  final String badge;
  final String imageAsset;
  final bool darkOverlay;

  const _HeroBannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageAsset,
    this.darkOverlay = true,
  });
}
