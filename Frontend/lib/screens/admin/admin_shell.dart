import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'admin_dashboard.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_customers.dart';
import 'admin_offers.dart';
import '../auth/login_screen.dart';
import '../home/main_shell.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void goToTab(int index) {
    if (index < 0 || index > 4) return;
    setState(() => _index = index);
  }

  void _openStoreFront() {
    // Customer shop (same as website Store Front). Back returns to admin.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn || !(auth.user?.isAdmin ?? false)) {
      return const LoginScreen();
    }

    final pages = [
      AdminDashboard(onNavigate: goToTab),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminCustomersScreen(),
      const AdminOffersScreen(),
    ];

    final titles = const [
      'Dashboard',
      'Products',
      'Orders',
      'Customers',
      'Offers',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${titles[_index]}'),
        actions: [
          TextButton.icon(
            onPressed: _openStoreFront,
            icon: const Icon(Icons.storefront_outlined, color: AppColors.gold),
            label: const Text(
              'Store Front',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.deepBlack,
        indicatorColor: AppColors.gold.withOpacity(0.25),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.gold),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.gold),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.gold),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.gold),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: AppColors.gold),
            label: 'Offers',
          ),
        ],
      ),
    );
  }
}