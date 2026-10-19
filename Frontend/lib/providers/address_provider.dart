import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressItem {
  final String id;
  String fullName;
  String phone;
  String line1;
  String line2;
  String city;
  String state;
  String pincode;
  bool isDefault;

  AddressItem({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
      };

  factory AddressItem.fromJson(Map<String, dynamic> j) => AddressItem(
        id: j['id']?.toString() ?? '',
        fullName: j['fullName']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        line1: j['line1']?.toString() ?? '',
        line2: j['line2']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        state: j['state']?.toString() ?? '',
        pincode: j['pincode']?.toString() ?? '',
        isDefault: j['isDefault'] == true,
      );
}

class AddressProvider with ChangeNotifier {
  static const _key = 'ff_addresses';
  final List<AddressItem> _items = [];

  List<AddressItem> get items => List.unmodifiable(_items);

  AddressItem? get defaultAddress {
    try {
      return _items.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _items.isEmpty ? null : _items.first;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        _items.add(AddressItem.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(AddressItem a) async {
    if (a.isDefault || _items.isEmpty) {
      for (final x in _items) {
        x.isDefault = false;
      }
      a.isDefault = true;
    }
    _items.add(a);
    await _persist();
    notifyListeners();
  }

  Future<void> update(AddressItem a) async {
    final i = _items.indexWhere((e) => e.id == a.id);
    if (i < 0) return;
    if (a.isDefault) {
      for (final x in _items) {
        x.isDefault = false;
      }
    }
    _items[i] = a;
    if (!_items.any((e) => e.isDefault) && _items.isNotEmpty) {
      _items.first.isDefault = true;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    if (_items.isNotEmpty && !_items.any((e) => e.isDefault)) {
      _items.first.isDefault = true;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setDefault(String id) async {
    for (final x in _items) {
      x.isDefault = x.id == id;
    }
    await _persist();
    notifyListeners();
  }
}