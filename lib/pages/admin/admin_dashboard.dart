import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_routes.dart';
import '../../core/supabase_client.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_users.dart';

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
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
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
    final shimmer = () => _ShimmerBox(radius: 16, height: 120);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats grid with subtle glass effect
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      isLoading
                          ? shimmer()
                          : _StatCard(
                              icon: Icons.inventory_2,
                              title: 'Products',
                              value: totalProducts.toString(),
                              color: Colors.blue,
                              trend: '+12% MoM',
                            ).animate().fadeIn().slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                              icon: Icons.shopping_bag,
                              title: 'Orders',
                              value: totalOrders.toString(),
                              color: Colors.orange,
                              trend: '+4% WoW',
                            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                                  icon: Icons.people,
                                  title: 'Users',
                                  value: totalUsers.toString(),
                                  color: Colors.green,
                                  trend: '+9 new',
                                )
                                .animate()
                                .fadeIn(delay: 140.ms)
                                .slideY(begin: 0.1),
                      isLoading
                          ? shimmer()
                          : _StatCard(
                                  icon: Icons.attach_money,
                                  title: 'Revenue',
                                  value: 'Rp ${_formatNumber(totalRevenue)}',
                                  color: Colors.purple,
                                  isSmallText: true,
                                  trend: '+7.1% QoQ',
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.1),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickActionButton(
                        icon: Icons.add_box,
                        title: 'Add Product',
                        subtitle: 'Tambah katalog baru',
                        onTap: () {
                          onTabSelected?.call(1);
                        },
                      ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.05),

                      _QuickActionButton(
                        icon: Icons.local_shipping,
                        title: 'Pending Orders',
                        subtitle: 'Pantau pesanan menunggu',
                        onTap: () {
                          // TODO: navigate to filtered orders
                        },
                      ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.05),

                      _QuickActionButton(
                        icon: Icons.image,
                        title: 'Upload Banner',
                        subtitle: 'Perbarui hero promo',
                        onTap: () {
                          // TODO: upload banner ke storage
                        },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallText ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trend != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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
    return Stack(
      children: [
        Container(
          height: 190,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5E3C), Color(0xFFB07A52), Color(0xFFF4D9B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        Positioned(
          right: -30,
          top: 20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Admin',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Performance Dashboard',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _GlassChip(
                      label: 'Revenue (paid)',
                      value: isLoading
                          ? '...'
                          : 'Rp ${_formatNumber(totalRevenue)}',
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GlassChip(
                      label: 'Orders',
                      value: isLoading ? '...' : totalOrders.toString(),
                      icon: Icons.receipt_long,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
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
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF8B5E3C)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
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
