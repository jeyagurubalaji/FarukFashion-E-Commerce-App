import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<Map<String, dynamic>> _users = [];
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
      final list = await ApiService().adminCustomers();
      if (mounted) {
        setState(() {
          _users =
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

  String _idOf(Map<String, dynamic> u) =>
      (u['id'] ?? u['_id'] ?? '').toString();

  bool _isAdmin(Map<String, dynamic> u) {
    final roles = u['roles'];
    if (roles is List) {
      return roles.any((r) => r.toString().contains('ADMIN'));
    }
    return false;
  }

  String _prefs(Map<String, dynamic> u) {
    final cats = u['preferredCategories'];
    if (cats is List && cats.isNotEmpty) {
      return cats.map((c) => c.toString().replaceAll('_', ' ')).join(', ');
    }
    return '—';
  }

  String _joined(Map<String, dynamic> u) {
    final raw = u['createdAt']?.toString();
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy-MM-dd').format(d);
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  Future<void> _openEdit(Map<String, dynamic> u) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditCustomerSheet(user: u),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final name =
        u['fullName']?.toString() ?? u['username']?.toString() ?? 'user';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete customer?',
            style: TextStyle(color: AppColors.white)),
        content: Text(
          'Permanently delete $name?\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().adminDeleteCustomer(_idOf(u));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _load,
                  child: _users.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text('No customers yet.',
                                  style:
                                      TextStyle(color: AppColors.textMuted)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          itemCount: _users.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 4, left: 4),
                                child: Text(
                                  'Registered users — edit or permanently delete',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }
                            final u = _users[i - 1];
                            final isAdmin = _isAdmin(u);
                            final active = u['active'] != false;
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.gold.withOpacity(0.12)),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 4, 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  u['fullName']?.toString() ??
                                                      u['username']
                                                          ?.toString() ??
                                                      '',
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              if (isAdmin) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.gold,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Text(
                                                    'ADMIN',
                                                    style: TextStyle(
                                                      color: AppColors.black,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (!active) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Text(
                                                    'OFF',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          _row('Email',
                                              u['email']?.toString() ?? '—'),
                                          _row('Phone',
                                              u['phone']?.toString() ?? '—'),
                                          _row('City',
                                              u['city']?.toString() ?? '—'),
                                          _row('Preferences', _prefs(u)),
                                          _row('Joined', _joined(u)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit,
                                              color: AppColors.gold, size: 20),
                                          onPressed: () => _openEdit(u),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 20),
                                          onPressed: () => _delete(u),
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
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCustomerSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _EditCustomerSheet({required this.user});

  @override
  State<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<_EditCustomerSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  bool _saving = false;

  String get _userId =>
      (widget.user['id'] ?? widget.user['_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final full = (widget.user['fullName'] ?? '').toString().trim();
    final parts = full.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    _firstName = TextEditingController(text: first);
    _lastName = TextEditingController(text: last);
    _phone =
        TextEditingController(text: widget.user['phone']?.toString() ?? '');
    _address =
        TextEditingController(text: widget.user['address']?.toString() ?? '');
    _city = TextEditingController(text: widget.user['city']?.toString() ?? '');
    _state =
        TextEditingController(text: widget.user['state']?.toString() ?? '');
    _pincode =
        TextEditingController(text: widget.user['pincode']?.toString() ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'pincode': _pincode.text.trim(),
    };
    try {
      await ApiService().adminUpdateCustomer(_userId, body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.charcoal,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final email = widget.user['email']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              'Edit Customer',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstName,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _dec('FIRST NAME'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lastName,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _dec('LAST NAME'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.white),
              decoration: _dec('PHONE'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              style: const TextStyle(color: AppColors.white),
              decoration: _dec('ADDRESS'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _city,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _dec('CITY'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _state,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _dec('STATE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: _dec('PINCODE'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SAVE',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}