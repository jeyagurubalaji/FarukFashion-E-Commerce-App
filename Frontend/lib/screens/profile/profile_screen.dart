import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../about/about_screen.dart';
import '../about/contact_screen.dart';
import '../admin/admin_shell.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Text(
                    auth.isLoggedIn
                        ? (auth.user?.fullName.isNotEmpty == true
                            ? auth.user!.fullName[0].toUpperCase()
                            : 'U')
                        : '?',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isLoggedIn
                            ? (auth.user?.fullName ?? 'User')
                            : 'Guest',
                        style: TextStyle(
                            color: onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      if (auth.isLoggedIn)
                        Text(
                          '@${auth.user?.username}',
                          style: TextStyle(
                              color: onSurface.withOpacity(0.6),
                              fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Dark mode',
              style: TextStyle(color: onSurface, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              theme.isDark ? 'Classic black & gold' : 'Light elegant',
              style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
            ),
            value: theme.isDark,
            activeColor: AppColors.gold,
            secondary: Icon(
              theme.isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.gold,
            ),
            onChanged: (v) => theme.setDark(v),
          ),
          const Divider(height: 24),
          if (!auth.isLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('SIGN IN / REGISTER'),
            )
          else ...[
            if (auth.user?.isAdmin == true)
              _tile(context, Icons.admin_panel_settings, 'Admin Panel', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminShell()),
                );
              }),
            _tile(context, Icons.receipt_long_outlined, 'My Orders', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            }),
            _tile(context, Icons.favorite_outline, 'Wishlist', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              );
            }),
            _tile(context, Icons.location_on_outlined, 'Addresses', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressesScreen()),
              );
            }),
            const Divider(height: 32),
            _tile(context, Icons.info_outline, 'About Us', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),
            _tile(context, Icons.support_agent, 'Contact & Support', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()));
            }),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                      color: AppColors.gold.withOpacity(0.7),
                      fontSize: 13,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.address,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: onSurface.withOpacity(0.5), fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '📞 ${AppConstants.supportPhone}',
                  style: TextStyle(
                      color: onSurface.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title, style: TextStyle(color: onSurface)),
      trailing: Icon(Icons.chevron_right, color: onSurface.withOpacity(0.4)),
      onTap: onTap,
    );
  }
}