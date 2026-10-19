import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/brand_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(AppConstants.address);
    await _launch(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const BrandLogo(size: 110, borderWidth: 3),
            const SizedBox(height: 20),
            Text(
              'FARUK FASHION',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.tagline,
              style: TextStyle(
                color: AppColors.lightGold,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Faruk Fashion brings you the best collection of Handbags, Trolley Bags, School Bags, College Bags, Office Bags, Sling Bags, Kids Bags and Travel Kits.\n\n'
              'We believe in Premium Quality, Durable & Stylish designs, Wide Variety and Trusted Service — all under one elegant roof.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            _infoRow(
              Icons.location_on,
              AppConstants.address,
              onTap: _openMaps,
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.phone,
              AppConstants.supportPhone,
              onTap: () => _launch('tel:${AppConstants.supportPhone}'),
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.email_outlined,
              AppConstants.supportEmail,
              onTap: () => _launch('mailto:${AppConstants.supportEmail}'),
            ),
            const SizedBox(height: 40),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ValueChip(icon: Icons.verified, label: 'Premium Quality'),
                _ValueChip(icon: Icons.workspace_premium, label: 'Durable'),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ValueChip(icon: Icons.diversity_3, label: 'Wide Variety'),
                _ValueChip(icon: Icons.handshake, label: 'Trusted Service'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: 14,
                    decoration: onTap != null
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: AppColors.gold,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.open_in_new,
                    size: 14, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ValueChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: AppColors.white, fontSize: 12)),
        ],
      ),
    );
  }
}