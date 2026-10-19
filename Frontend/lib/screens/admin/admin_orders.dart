import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'ALL';

  static const statuses = [
    'PLACED',
    'CONFIRMED',
    'PACKED',
    'SHIPPED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
    'RETURN_REQUESTED',
    'RETURNED',
  ];

  static const filterOptions = [
    'ALL',
    'PLACED',
    'CONFIRMED',
    'PACKED',
    'SHIPPED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
    'RETURN_REQUESTED',
    'RETURNED',
  ];

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
      final list = await ApiService().adminOrders(
        status: _statusFilter == 'ALL' ? null : _statusFilter,
      );
      if (mounted) {
        setState(() {
          _orders =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  String _idOf(Map<String, dynamic> o) =>
      (o['id'] ?? o['_id'] ?? '').toString();

  String _fmtDate(dynamic raw) {
    if (raw == null) return '';
    try {
      return DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return raw.toString().length >= 10
          ? raw.toString().substring(0, 10)
          : raw.toString();
    }
  }

  int _itemCount(Map<String, dynamic> o) {
    final items = o['items'];
    if (items is List) return items.length;
    return 0;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.greenAccent;
      case 'CANCELLED':
      case 'RETURNED':
        return AppColors.error;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return Colors.lightBlueAccent;
      case 'CONFIRMED':
      case 'PACKED':
        return AppColors.gold;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _payColor(String pay) {
    switch (pay.toUpperCase()) {
      case 'PAID':
        return AppColors.gold;
      case 'FAILED':
      case 'REFUNDED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> o, String newStatus) async {
    final id = _idOf(o);
    final current = o['status']?.toString() ?? '';
    if (newStatus == current) return;
    try {
      await ApiService().adminUpdateOrderStatus(id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status → $newStatus')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteOrder(Map<String, dynamic> o) async {
    final id = _idOf(o);
    final number = o['orderNumber']?.toString() ?? id;
    if (id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete order?',
          style: TextStyle(color: AppColors.gold),
        ),
        content: Text(
          'Delete order $number permanently?\nStock will be restored if the order was not cancelled.\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService().adminDeleteOrder(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showDetails(Map<String, dynamic> o) async {
    final items = (o['items'] is List)
        ? List<Map<String, dynamic>>.from((o['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];
    final addr = o['shippingAddress'];
    String addrText = '—';
    if (addr is Map) {
      addrText = [
        addr['line1'],
        addr['line2'],
        addr['city'],
        addr['state'],
        addr['pincode'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              o['orderNumber']?.toString() ?? _idOf(o),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Customer: ${o['customerName'] ?? '—'}',
                style: const TextStyle(color: AppColors.white)),
            Text('Phone: ${o['customerPhone'] ?? '—'}',
                style: const TextStyle(color: AppColors.textSecondary)),
            Text('Email: ${o['customerEmail'] ?? '—'}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Ship to: $addrText',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Text(
              'Total: ₹${o['totalAmount'] ?? 0}  ·  ${o['paymentMethod'] ?? ''}  ·  ${o['paymentStatus'] ?? ''}',
              style: const TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('Items',
                style: TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${it['productName'] ?? 'Item'} × ${it['quantity'] ?? 1}  ·  ₹${it['totalPrice'] ?? it['unitPrice'] ?? 0}',
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                )),
            const SizedBox(height: 16),
            const Text('Update status',
                style: TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((s) {
                final current = o['status']?.toString() ?? '';
                final selected = s == current;
                return ChoiceChip(
                  label: Text(s.replaceAll('_', ' ')),
                  selected: selected,
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.black : AppColors.white,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    Navigator.pop(ctx);
                    _updateStatus(o, s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteOrder(o);
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text(
                  'DELETE ORDER',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage customer orders & shipping',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.gold.withOpacity(0.25)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      dropdownColor: AppColors.charcoal,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.gold),
                      style: const TextStyle(color: AppColors.white),
                      items: filterOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s == 'ALL'
                                      ? 'All Statuses'
                                      : s.replaceAll('_', ' '),
                                  style: const TextStyle(
                                      color: AppColors.white),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _statusFilter = v);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _load,
                        child: _orders.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No orders found.',
                                      style: TextStyle(
                                          color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 24),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final o = _orders[i];
                                  final status =
                                      o['status']?.toString() ?? '';
                                  final pay =
                                      o['paymentStatus']?.toString() ??
                                          'PENDING';
                                  final method =
                                      o['paymentMethod']?.toString() ?? '';
                                  final currentStatus =
                                      statuses.contains(status)
                                          ? status
                                          : statuses.first;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.gold
                                              .withOpacity(0.12)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 10, 8, 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      o['orderNumber']
                                                              ?.toString() ??
                                                          _idOf(o),
                                                      style: const TextStyle(
                                                        color: AppColors.gold,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      _fmtDate(
                                                          o['createdAt']),
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textMuted,
                                                          fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Details',
                                                icon: const Icon(Icons.edit,
                                                    color: AppColors.gold,
                                                    size: 20),
                                                onPressed: () =>
                                                    _showDetails(o),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete order',
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: AppColors.error,
                                                    size: 20),
                                                onPressed: () =>
                                                    _deleteOrder(o),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            o['customerName']?.toString() ??
                                                '—',
                                            style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            o['customerPhone']?.toString() ??
                                                '',
                                            style: const TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                '${_itemCount(o)} item(s)',
                                                style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '₹${o['totalAmount'] ?? 0}',
                                                style: const TextStyle(
                                                  color: AppColors.gold,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: _payColor(pay)),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                                child: Text(
                                                  pay,
                                                  style: TextStyle(
                                                    color: _payColor(pay),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (method.isNotEmpty) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  method,
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .textMuted,
                                                      fontSize: 10),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                                child: Text(
                                                  status.replaceAll('_', ' '),
                                                  style: TextStyle(
                                                    color: _statusColor(
                                                        status),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                'Update: ',
                                                style: TextStyle(
                                                    color:
                                                        AppColors.textMuted,
                                                    fontSize: 12),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.charcoal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: AppColors.gold
                                                            .withOpacity(
                                                                0.2)),
                                                  ),
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child:
                                                        DropdownButton<String>(
                                                      value: currentStatus,
                                                      isExpanded: true,
                                                      isDense: true,
                                                      dropdownColor:
                                                          AppColors.charcoal,
                                                      style: const TextStyle(
                                                          color:
                                                              AppColors.white,
                                                          fontSize: 12),
                                                      items: statuses
                                                          .map((s) =>
                                                              DropdownMenuItem(
                                                                value: s,
                                                                child: Text(s
                                                                    .replaceAll(
                                                                        '_',
                                                                        ' ')),
                                                              ))
                                                          .toList(),
                                                      onChanged: (v) {
                                                        if (v != null) {
                                                          _updateStatus(o, v);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}