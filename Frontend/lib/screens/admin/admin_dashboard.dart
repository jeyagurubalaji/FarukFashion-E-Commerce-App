import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  /// 0 Home · 1 Products · 2 Orders · 3 Customers · 4 Offers
  final void Function(int tabIndex)? onNavigate;

  const AdminDashboard({super.key, this.onNavigate});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ApiService().adminDashboard();
      if (mounted) {
        setState(() {
          _data = d;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _go(int tab) => widget.onNavigate?.call(tab);

  String _num(dynamic v) {
    if (v == null) return '0';
    if (v is num) return v is double ? v.toStringAsFixed(0) : v.toString();
    return v.toString();
  }

  String _money(dynamic v) {
    if (v == null) return '₹0';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    return '₹${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final d = _data!;
    final recentOrders = (d['recentOrders'] as List?) ?? [];
    final lowStock = (d['lowStock'] as List?) ?? [];

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'Faruk Fashion · Overview',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statCard(
                'TOTAL PRODUCTS',
                _num(d['totalProducts']),
                onTap: () => _go(1),
              ),
              _statCard(
                'ACTIVE PRODUCTS',
                _num(d['activeProducts']),
                onTap: () => _go(1),
              ),
              _statCard(
                'TOTAL ORDERS',
                _num(d['totalOrders']),
                onTap: () => _go(2),
              ),
              _statCard(
                'PENDING ORDERS',
                _num(d['pendingOrders']),
                onTap: () => _go(2),
              ),
              _statCard(
                'CUSTOMERS',
                _num(d['totalCustomers']),
                onTap: () => _go(3),
              ),
              _statCard(
                'REVENUE (PAID)',
                _money(d['totalRevenue']),
                highlight: true,
                onTap: () => _go(2),
              ),
              _statCard(
                'LOW STOCK ITEMS',
                _num(lowStock.length),
                danger: lowStock.isNotEmpty,
                onTap: () => _go(1),
              ),
              _statCard(
                'ACTIVE OFFERS',
                _num(d['totalOffers']),
                onTap: () => _go(4),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => _go(2),
                child: const Text(
                  'See all',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('ORDER',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 3,
                          child: Text('CUSTOMER',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('TOTAL',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('STATUS',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                if (recentOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recent orders',
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ...recentOrders.take(8).map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    final status = o['status']?.toString() ?? '';
                    return InkWell(
                      onTap: () => _go(2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                o['orderNumber']?.toString() ??
                                    (o['_id'] ?? o['id'] ?? '').toString(),
                                style: const TextStyle(
                                    color: AppColors.gold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                o['customerName']?.toString() ?? '—',
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _money(o['totalAmount']),
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Low Stock Alert',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => _go(1),
                child: const Text(
                  'See products',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('PRODUCT',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Text('STOCK',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                if (lowStock.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No low-stock items',
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ...lowStock.map((raw) {
                    final p = Map<String, dynamic>.from(raw as Map);
                    return InkWell(
                      onTap: () => _go(1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p['name']?.toString() ?? '—',
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 13),
                              ),
                            ),
                            Text(
                              _num(p['stockQuantity']),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    bool highlight = false,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final width = (MediaQuery.of(context).size.width - 42) / 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width.clamp(140, 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: danger
                  ? AppColors.error.withOpacity(0.4)
                  : AppColors.gold.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: danger
                      ? AppColors.error
                      : (highlight ? AppColors.gold : AppColors.white),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}