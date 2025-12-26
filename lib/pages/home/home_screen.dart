// lib/pages/home/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/cart_manager.dart';
import '../../core/supabase_client.dart';
import '../../core/ui_constants.dart';
import '../../models/product.dart';
import '../admin/admin_dashboard.dart';
import '../cart/cart_screen.dart';
import '../product/details_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/my_orders_screen.dart';
import '../widgets/categories.dart';
import '../widgets/item_card.dart';
import '../wishlist/wishlist_screen.dart';
import '../promo/promo_screen.dart';
import '../help/help_screen.dart';

// Palet warna khusus home (senada dengan login coklat)
const Color _primaryBrown = Color(0xFF8B5E3C);
const Color _textDark = Color(0xFF1F2933);
const Color _textLight = Color(0xFF9AA5B1);

class _Responsive {
  _Responsive(this.width);
  final double width;

  bool get isMobile => width < 700;
  bool get isTablet => width >= 700 && width < 1100;
  bool get isDesktop => width >= 1100;

  double get horizontalPadding => isDesktop
      ? 32
      : isTablet
      ? 24
      : 16;

  double get cardAspectRatio => isDesktop
      ? 0.95
      : isTablet
      ? 0.8
      : 0.68;

  int get gridCrossAxisCount => isDesktop
      ? 4
      : isTablet
      ? 3
      : 2;

  double get heroHeight => isDesktop
      ? 320
      : isTablet
      ? 280
      : 240;

  double get trendingHeight => isDesktop
      ? 190
      : isTablet
      ? 170
      : 150;

  static _Responsive of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return _Responsive(width);
  }
}

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

  // profile info for drawer
  String? _profileName;
  String? _avatarUrl;
  bool _isAdmin = false;

  // --- data dari Supabase ---
  final List<AppProduct> _allProducts = [];
  List<AppProduct> _visibleProducts = [];
  final List<String> _categoryLabels = ['All'];
  String? _selectedCategoryName = 'All';
  String _searchQuery = '';
  final List<String> _quickFilters = const [
    'All',
    'Best seller',
    'New in',
    '< 1 Juta',
  ];
  String _selectedQuickFilter = 'All';

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
    await Future.wait([_loadProfileInfo(), _loadData()]);
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

  Future<void> _loadProfileInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, avatar_url, email, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profileName = (data?['full_name'] as String?)?.trim();
        _avatarUrl = data?['avatar_url'] as String?;
        _profileName ??= user.email ?? 'Akun Saya';
        _isAdmin = data?['role'] == 'admin';
      });
    } catch (_) {
      // Biarkan default jika gagal
    }
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

    switch (_selectedQuickFilter) {
      case 'Best seller':
        base = base.where((p) => p.isBestSeller);
        break;
      case 'New in':
        // sort handled below to prioritize produk terbaru
        break;
      case '< 1 Juta':
        base = base.where((p) => p.price < 1000000);
        break;
      default:
        break;
    }
    _visibleProducts = base.toList();

    if (_selectedQuickFilter == 'New in') {
      _visibleProducts.sort((a, b) => b.id.compareTo(a.id));
    }
  }

  void _onQuickFilterSelected(String value) {
    setState(() {
      _selectedQuickFilter = value;
      _applyFilter();
    });
  }

  List<AppProduct> get _trendingProducts {
    final best = _allProducts.where((p) => p.isBestSeller).toList();
    if (best.isNotEmpty) return best.take(6).toList();
    return _allProducts.take(6).toList();
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
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));

    // Redirect ke login screen immediately
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
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
    final bp = _Responsive.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        onProfile: _openProfileSheet,
        onOrders: _openOrders,
        onWishlist: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WishlistScreen()),
          );
        },
        onVouchers: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PromoScreen()),
          );
        },
        onHelp: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          );
        },
        onAdmin: _isAdmin
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              }
            : null,
        onLogout: _logout,
        profileName: _profileName,
        avatarUrl: _avatarUrl,
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
                    final double maxWidth = bp.isDesktop
                        ? 1200
                        : bp.isTablet
                        ? 1000
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
                                            _HeaderHero(
                                              profileName: _profileName,
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              height: bp.heroHeight,
                                              child: _HeroCarousel(
                                                banners: _heroBanners,
                                                controller: _heroController,
                                                currentIndex: _currentHero,
                                                onChanged: (index) {
                                                  setState(() {
                                                    _currentHero = index;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            _PromoStrip(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const PromoScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 18),
                                            _QuickFilterBar(
                                              filters: _quickFilters,
                                              selected: _selectedQuickFilter,
                                              onSelected:
                                                  _onQuickFilterSelected,
                                            ),
                                            const SizedBox(height: 14),
                                            Categories(
                                              categories: _categoryLabels,
                                              selectedLabel:
                                                  _selectedCategoryName,
                                              onSelected: _onCategorySelected,
                                            ),
                                            const SizedBox(height: 22),
                                            const _SectionHeader(
                                              title: 'Trending minggu ini',
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              height: bp.trendingHeight,
                                              child: _TrendingScroller(
                                                products: _trendingProducts,
                                                onTap: (product) {
                                                  Navigator.of(context).push(
                                                    _detailsRoute(product),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 22),
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: bp.horizontalPadding,
                                        vertical: 8,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  bp.gridCrossAxisCount,
                                              mainAxisSpacing: 18,
                                              crossAxisSpacing: 18,
                                              // 0.68 → cell sedikit lebih tinggi,
                                              // menghindari overflow kuning-hitam
                                              childAspectRatio:
                                                  bp.cardAspectRatio,
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
                                              Navigator.of(
                                                context,
                                              ).push(_detailsRoute(product));
                                            },
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

  // Route transisi modern untuk halaman detail: fade + slide up
  Route _detailsRoute(AppProduct product) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DetailsScreen(product: product),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  // AppBar custom dengan badge cart
  Widget _buildAppBar() {
    final bp = _Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: bp.horizontalPadding,
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
    this.onAdmin,
    this.profileName,
    this.avatarUrl,
  });

  final VoidCallback onProfile;
  final VoidCallback onOrders;
  final VoidCallback onWishlist;
  final VoidCallback onVouchers;
  final VoidCallback onHelp;
  final VoidCallback? onAdmin;
  final VoidCallback onLogout;
  final String? profileName;
  final String? avatarUrl;

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
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _primaryBrown,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profileName ?? 'Akun Saya',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            if (onAdmin != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel'),
                onTap: onAdmin,
              ),
            ],
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

class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.profileName});

  final String? profileName;

  @override
  Widget build(BuildContext context) {
    final greeting = (profileName?.isNotEmpty ?? false)
        ? 'Halo, ${profileName!.split(' ').first}!'
        : 'Halo, Sneakerhead!';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B0E), Color(0xFF8B5E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kurasi drops baru, promo, dan best seller hari ini.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFB923C),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFB923C).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Fresh drop',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_offer, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Voucher + free ongkir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cek kode promo terbaru, klaim sebelum habis.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterBar extends StatelessWidget {
  const _QuickFilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  selected: selected == f,
                  onSelected: (_) => onSelected(f),
                  label: Text(f),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected == f ? Colors.white : _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: _primaryBrown,
                  side: BorderSide(
                    color: selected == f ? _primaryBrown : Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TrendingScroller extends StatelessWidget {
  const _TrendingScroller({required this.products, required this.onTap});

  final List<AppProduct> products;
  final ValueChanged<AppProduct> onTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return _TrendingCard(product: product, onTap: () => onTap(product));
        },
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.product, required this.onTap});

  final AppProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF7F0E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF3E8E2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.photo_camera_outlined, color: _textDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.isBestSeller)
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatRupiah(product.price),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        Text(
          'See all',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            decoration: TextDecoration.none,
          ),
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
