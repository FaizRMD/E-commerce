import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_routes.dart';
import '../../core/supabase_client.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_users.dart';
import 'admin_promos.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  // Stats data
  int _totalProducts = 0;
  int _totalOrders = 0;
  int _totalUsers = 0;
  int _totalRevenue = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    AdminProductsScreen(),
    AdminOrdersScreen(),
    AdminPromoScreen(),
    AdminUsersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Get total products
      final productsData = await supabase.from('products').select('id');

      // Get total orders
      final ordersData = await supabase.from('orders').select('id');

      // Get total users
      final usersData = await supabase.from('profiles').select('id');

      // Get total revenue
      final revenueData = await supabase
          .from('orders')
          .select('total')
          .eq('status', 'paid');

      int revenue = 0;
      for (var order in revenueData) {
        revenue += (order['total'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalProducts = (productsData as List).length;
          _totalOrders = (ordersData as List).length;
          _totalUsers = (usersData as List).length;
          _totalRevenue = revenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Yakin ingin keluar dari admin panel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await supabase.auth.signOut();
                if (mounted) {
                  AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
                }
              }
            },
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _DashboardHome(
              totalProducts: _totalProducts,
              totalOrders: _totalOrders,
              totalUsers: _totalUsers,
              totalRevenue: _totalRevenue,
              isLoading: _isLoading,
              onRefresh: _loadStats,
              onTabSelected: (index) => setState(() => _currentIndex = index),
            )
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B5E3C),
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Pengguna',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final int totalProducts;
  final int totalOrders;
  final int totalUsers;
  final int totalRevenue;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onTabSelected;

  const _DashboardHome({
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalUsers = 0,
    this.totalRevenue = 0,
    this.isLoading = false,
    this.onRefresh,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1200;
    final shimmer = () => _ShimmerBox(radius: 16, height: 140);

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header with gradient & glass overlay
            _HeroHeader(
              isLoading: isLoading,
              totalRevenue: totalRevenue,
              totalOrders: totalOrders,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section Title
                  Text(
                    'Ringkasan Statistik',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2933),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Stats grid - responsive
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 4),
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                    childAspectRatio: isMobile ? 0.95 : 1.3,
                    children: [
                      isLoading
                          ? shimmer()
                          : _StatCard(
                              icon: Icons.inventory_2,
                              title: 'Produk',
                              value: totalProducts.toString(),
                              color: Colors.blue,
                              trend: '+12%',
                            ).animate().fadeIn().slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                              icon: Icons.shopping_bag,
                              title: 'Pesanan',
                              value: totalOrders.toString(),
                              color: Colors.orange,
                              trend: '+4%',
                            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                                  icon: Icons.people,
                                  title: 'Pengguna',
                                  value: totalUsers.toString(),
                                  color: Colors.green,
                                  trend: '+9',
                                )
                                .animate()
                                .fadeIn(delay: 140.ms)
                                .slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                                  icon: Icons.attach_money,
                                  title: 'Pendapatan',
                                  value: 'Rp ${_formatNumber(totalRevenue)}',
                                  color: const Color(0xFF8B5E3C),
                                  isSmallText: true,
                                  trend: '+7.1%',
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.1),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions Section
                  Text(
                    'Aksi Cepat',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2933),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick action buttons - improved responsive layout
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                    crossAxisSpacing: isMobile ? 0 : 16,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 0.85 : 1,
                    children: [
                      _QuickActionButton(
                        icon: Icons.add_circle_outline,
                        title: 'Tambah Produk',
                        subtitle: 'Tambah katalog baru',
                        onTap: () {
                          onTabSelected?.call(1);
                        },
                        color: Colors.blue,
                      ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.05),

                      _QuickActionButton(
                        icon: Icons.local_shipping,
                        title: 'Pesanan',
                        subtitle: 'Kelola pesanan',
                        onTap: () {
                          onTabSelected?.call(2);
                        },
                        color: Colors.orange,
                      ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.05),

                      _QuickActionButton(
                        icon: Icons.local_offer_outlined,
                        title: 'Promo',
                        subtitle: 'Kelola voucher',
                        onTap: () {
                          onTabSelected?.call(3);
                        },
                        color: Colors.purple,
                      ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.05),
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isSmallText;
  final String? trend;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isSmallText = false,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(height: 8),

          // Stats Info
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Value - with better sizing
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallText ? 16 : 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2933),
                    ),
                  ),
                ),

                // Trend badge - simplified
                if (trend != null) ...[
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 10, color: color),
                          const SizedBox(width: 3),
                          Text(
                            trend!,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  } // end build of _StatCard
} // <-- ADDED: close _StatCard class

class _HeroHeader extends StatelessWidget {
  final bool isLoading;
  final int totalRevenue;
  final int totalOrders;

  const _HeroHeader({
    required this.isLoading,
    required this.totalRevenue,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        // Background gradient
        Container(
          height: isMobile ? 200 : 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5E3C), Color(0xFFB07A52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),

        // Decorative circles
        Positioned(
          right: -40,
          top: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 20 : 24,
            isMobile ? 16 : 20,
            isMobile ? 20 : 24,
            isMobile ? 20 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang, Admin',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Dashboard Performa',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 18),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _GlassChip(
                      label: 'Pendapatan',
                      value: isLoading
                          ? 'Rp 0'
                          : 'Rp ${_formatNumber(totalRevenue)}',
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GlassChip(
                      label: 'Pesanan',
                      value: isLoading ? '0' : totalOrders.toString(),
                      icon: Icons.receipt_long,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GlassChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double radius;
  final double? height;

  const _ShimmerBox({this.radius = 12, this.height});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        ShimmerEffect(
          duration: 1200.ms,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
        ),
      ],
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFF8B5E3C),
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 20 : 12,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container dengan animasi
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2933),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                widget.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
}
