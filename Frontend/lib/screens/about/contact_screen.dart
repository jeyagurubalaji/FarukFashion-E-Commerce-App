import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
      appBar: AppBar(title: const Text('Contact Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We are here for you 24×7',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Reach out anytime — our support team is ready to help.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _contactCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: AppConstants.supportPhone,
              onTap: () => _launch('tel:${AppConstants.supportPhone}'),
            ),
            const SizedBox(height: 14),
            _contactCard(
              icon: Icons.chat,
              title: 'WhatsApp',
              subtitle: 'Chat with us instantly',
              onTap: () => _launch(
                  'https://wa.me/91${AppConstants.supportPhone}'),
            ),
            const SizedBox(height: 14),
            _contactCard(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: AppConstants.supportEmail,
              onTap: () =>
                  _launch('mailto:${AppConstants.supportEmail}'),
            ),
            const SizedBox(height: 14),
            _contactCard(
              icon: Icons.location_on_outlined,
              title: 'Visit Store',
              subtitle: AppConstants.address,
              onTap: _openMaps, // opens Google Maps
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withOpacity(0.25)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.support_agent, color: AppColors.gold, size: 40),
                  SizedBox(height: 12),
                  Text(
                    '24×7 Customer Support',
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Premium Quality • Durable & Stylish\nWide Variety • Trusted Service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}