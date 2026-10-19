import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import 'home_screen.dart';
import '../product/categories_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.deepBlack : Colors.white;
    final unselected =
        isDark ? AppColors.textMuted : const Color(0xFF888888);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.gold.withOpacity(isDark ? 0.2 : 0.3),
              width: 0.6,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: barBg,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: unselected,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: badges.Badge(
                showBadge: cartCount > 0,
                badgeContent: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.gold,
                  padding: EdgeInsets.all(4),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              activeIcon: badges.Badge(
                showBadge: cartCount > 0,
                badgeContent: Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.gold,
                  padding: EdgeInsets.all(4),
                ),
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}