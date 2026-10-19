import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../product/product_list_screen.dart';
import '../product/product_detail_screen.dart';
import '../about/contact_screen.dart';
import '../about/about_screen.dart';
import '../product/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<ProductModel> _featured = [];
  bool _loading = true;

  List<Map<String, String>> _offers = [
    {
      'title': 'Festive Sale',
      'subtitle': 'Up to 30% OFF on Handbags',
      'tag': 'OFFER',
    },
    {
      'title': 'School Special',
      'subtitle': 'Special deals on Kids Bags',
      'tag': 'NEW',
    },
    {
      'title': 'Travel Ready',
      'subtitle': 'Flat deals on Trolley Bags',
      'tag': 'HOT',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await _api.getProducts(page: 0, size: 24);

      List<Map<String, dynamic>> banners = [];
      try {
        banners = await _api.getHomeBanners();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _featured = products;
          if (banners.isNotEmpty) {
            _offers = banners
                .map((b) => {
                      'title': (b['title'] ?? 'Offer').toString(),
                      'subtitle': (b['description'] ?? '').toString(),
                      'tag': 'OFFER',
                    })
                .toList();
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.black : const Color(0xFFF7F5F0);
    final appBarBg = isDark ? AppColors.deepBlack : Colors.white;
    final catTileBg = isDark ? AppColors.charcoal : Colors.white;
    final catLabel =
        isDark ? AppColors.textSecondary : const Color(0xFF555555);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 70,
              floating: true,
              pinned: true,
              backgroundColor: appBarBg,
              title: Column(
                children: [
                  Text(
                    'FARUK FASHION',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                  ),
                  Text(
                    AppConstants.tagline,
                    style: TextStyle(
                      color: AppColors.lightGold.withOpacity(0.9),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.gold),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Offers banner (always dark elegant)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 160,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.92,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                  items: _offers.map((offer) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppColors.bannerGradient,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    offer['tag']!,
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  offer['title']!,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  offer['subtitle']!,
                                  style: TextStyle(
                                    color:
                                        AppColors.lightGold.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Shop by Category
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Shop by Category'),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: AppConstants.categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = AppConstants.categories[i];
                        return GestureDetector(
                          onTap: () {
                            final code = cat['code'] ?? '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductListScreen(
                                  categoryCode: code.isEmpty ? null : code,
                                  categoryName: cat['name']!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: catTileBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.gold.withOpacity(0.35),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat['icon']!,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat['name']!,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: catLabel,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Best Collection
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Best Collection',
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(
                            categoryName: 'All Products',
                          ),
                        ),
                      );
                    },
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.gold),
                      ),
                    )
                  else if (_featured.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No products yet.\nAdd products from Admin panel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMuted
                                : const Color(0xFF888888),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _featured.length,
                        itemBuilder: (ctx, i) {
                          return ProductCard(
                            product: _featured[i],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    productId: _featured[i].id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Trust badges
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TrustBadge(
                        icon: Icons.verified, label: 'Premium\nQuality'),
                    _TrustBadge(
                        icon: Icons.workspace_premium,
                        label: 'Durable &\nStylish'),
                    _TrustBadge(
                        icon: Icons.diversity_3, label: 'Wide\nVariety'),
                    _TrustBadge(
                        icon: Icons.handshake, label: 'Trusted\nService'),
                  ],
                ),
              ),
            ),

            // Quick links
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Row(
                  children: [
                    Expanded(
                        child: _QuickLink(
                            title: 'About Us', screen: AboutScreen())),
                    SizedBox(width: 12),
                    Expanded(
                        child: _QuickLink(
                            title: 'Contact', screen: ContactScreen())),
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

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : const Color(0xFF555555),
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String title;
  final Widget screen;
  const _QuickLink({required this.title, required this.screen});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(title),
    );
  }
}