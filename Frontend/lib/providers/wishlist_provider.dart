import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  static const _key = 'ff_wishlist_ids';
  final Set<String> _ids = {};
  final Map<String, ProductModel> _cache = {};

  Set<String> get ids => _ids;
  List<ProductModel> get products =>
      _ids.map((id) => _cache[id]).whereType<ProductModel>().toList();

  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _ids
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());
  }

  Future<void> toggle(ProductModel product) async {
    final id = product.id;
    if (_ids.contains(id)) {
      _ids.remove(id);
      _cache.remove(id);
    } else {
      _ids.add(id);
      _cache[id] = product;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _ids.remove(id);
    _cache.remove(id);
    await _persist();
    notifyListeners();
  }

  void remember(ProductModel product) {
    if (_ids.contains(product.id)) {
      _cache[product.id] = product;
    }
  }
}