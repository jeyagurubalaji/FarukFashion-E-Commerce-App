import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  List<Map<String, dynamic>> _offers = [];
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
      final list = await ApiService().adminOffers();
      if (mounted) {
        setState(() {
          _offers = list;
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
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('M/d/yyyy, h:mm a').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  bool _isLive(Map<String, dynamic> o) {
    if (o['active'] != true) return false;
    try {
      final now = DateTime.now();
      final start = DateTime.parse(o['startDate'].toString());
      final end = DateTime.parse(o['endDate'].toString());
      return !now.isBefore(start) && !now.isAfter(end);
    } catch (_) {
      return o['active'] == true;
    }
  }

  Future<void> _openForm({Map<String, dynamic>? offer}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OfferFormSheet(offer: offer),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> o) async {
    final title = o['title']?.toString() ?? 'offer';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete offer?',
            style: TextStyle(color: AppColors.white)),
        content: Text('Permanently delete "$title"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
      await ApiService().adminDeleteOffer(_idOf(o));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer deleted')),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.add),
        label: const Text('ADD OFFER',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openForm(),
      ),
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
                  child: _offers.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No offers yet.\nTap ADD OFFER to create one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _offers.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 4, left: 4),
                                child: Text(
                                  'Change the gold strip on the home page. Set start and end dates',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }
                            final o = _offers[i - 1];
                            final live = _isLive(o);
                            final onHome = o['showOnHomeBanner'] == true;
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
                                          Text(
                                            o['title']?.toString() ?? '',
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            o['description']?.toString() ?? '',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Start: ${_fmtDate(o['startDate'])}',
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            'End: ${_fmtDate(o['endDate'])}',
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'On Home: ${onHome ? 'Yes' : 'No'}',
                                                style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: live
                                                      ? AppColors.gold
                                                      : AppColors.charcoal,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  live
                                                      ? 'LIVE ON SITE'
                                                      : (o['active'] == true
                                                          ? 'SCHEDULED'
                                                          : 'OFF'),
                                                  style: TextStyle(
                                                    color: live
                                                        ? AppColors.black
                                                        : AppColors.textMuted,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit,
                                              color: AppColors.gold, size: 20),
                                          onPressed: () =>
                                              _openForm(offer: o),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 20),
                                          onPressed: () => _delete(o),
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
}

class _OfferFormSheet extends StatefulWidget {
  final Map<String, dynamic>? offer;
  const _OfferFormSheet({this.offer});

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _value;
  late final TextEditingController _minOrder;
  late final TextEditingController _priority;

  String _type = 'PERCENTAGE';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _showOnHome = true;
  bool _active = true;
  bool _saving = false;

  static const _types = [
    {'code': 'PERCENTAGE', 'label': 'Percentage off'},
    {'code': 'FLAT', 'label': 'Flat amount off'},
    {'code': 'BUY_X_GET_Y', 'label': 'Buy X Get Y'},
  ];

  bool get _isEdit => widget.offer != null;

  String get _offerId =>
      (widget.offer?['id'] ?? widget.offer?['_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _title = TextEditingController(text: o?['title']?.toString() ?? '');
    _desc = TextEditingController(text: o?['description']?.toString() ?? '');
    _value = TextEditingController(
        text: o?['discountValue'] != null
            ? o!['discountValue'].toString()
            : '');
    _minOrder = TextEditingController(
        text: o?['minOrderAmount'] != null
            ? o!['minOrderAmount'].toString()
            : '');
    _priority = TextEditingController(text: (o?['priority'] ?? 1).toString());

    if (o != null) {
      final t = o['type']?.toString() ?? 'PERCENTAGE';
      if (_types.any((e) => e['code'] == t)) _type = t;
      _showOnHome = o['showOnHomeBanner'] != false;
      _active = o['active'] != false;
      try {
        if (o['startDate'] != null) {
          _start = DateTime.parse(o['startDate'].toString()).toLocal();
        }
        if (o['endDate'] != null) {
          _end = DateTime.parse(o['endDate'].toString()).toLocal();
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _value.dispose();
    _minOrder.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.charcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.charcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _start = combined;
      } else {
        _end = combined;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'type': _type,
      'discountValue': _value.text.trim().isEmpty
          ? null
          : double.tryParse(_value.text.trim()),
      'minOrderAmount': _minOrder.text.trim().isEmpty
          ? null
          : double.tryParse(_minOrder.text.trim()),
      'priority': int.tryParse(_priority.text.trim()) ?? 1,
      'startDate': _start.toUtc().toIso8601String(),
      'endDate': _end.toUtc().toIso8601String(),
      'showOnHomeBanner': _showOnHome,
      'active': _active,
    };

    try {
      if (_isEdit) {
        await ApiService().adminUpdateOffer(_offerId, body);
      } else {
        await ApiService().adminCreateOffer(body);
      }
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
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _dec(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MM/dd/yyyy  hh:mm a').format(value),
                style: const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),
            const Icon(Icons.calendar_today,
                color: AppColors.gold, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
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
                _isEdit ? 'Edit Offer' : 'Add Offer',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Title and description appear on the gold bar under the home hero. Use dates to show only on chosen days.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                style: const TextStyle(color: AppColors.white),
                decoration: _dec('TITLE * (E.G. FESTIVAL SPECIAL)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                style: const TextStyle(color: AppColors.white),
                maxLines: 2,
                decoration:
                    _dec('DESCRIPTION * (E.G. FLAT 15% OFF ON HANDBAGS)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      'START DATE AND TIME *',
                      _start,
                      () => _pickDateTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateField(
                      'END DATE AND TIME *',
                      _end,
                      () => _pickDateTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      dropdownColor: AppColors.charcoal,
                      decoration: _dec('TYPE'),
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                      items: _types
                          .map((t) => DropdownMenuItem(
                                value: t['code'],
                                child: Text(t['label']!,
                                    style: const TextStyle(
                                        color: AppColors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v ?? _type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _value,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('VALUE (OPTIONAL)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minOrder,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('MIN ORDER RS (OPTIONAL)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priority,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('DISPLAY ORDER'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _showOnHome,
                    activeColor: AppColors.gold,
                    onChanged: (v) =>
                        setState(() => _showOnHome = v ?? true),
                  ),
                  const Flexible(
                    child: Text('Show on home gold banner',
                        style:
                            TextStyle(color: AppColors.white, fontSize: 13)),
                  ),
                  Checkbox(
                    value: _active,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _active = v ?? true),
                  ),
                  const Text('Active',
                      style: TextStyle(color: AppColors.white, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: BorderSide(
                            color: AppColors.gold.withOpacity(0.5)),
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEdit ? 'UPDATE OFFER' : 'CREATE OFFER',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}