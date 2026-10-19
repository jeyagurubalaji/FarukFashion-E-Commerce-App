import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.total);

  void addItem(ProductModel product, {String? color, String? size, int qty = 1}) {
    final index = _items.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedColor == color &&
        item.selectedSize == size);

    if (index >= 0) {
      _items[index].quantity += qty;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: qty,
        selectedColor: color,
        selectedSize: size,
      ));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    _items[index].quantity = quantity;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Map<String, dynamic> toOrderPayload({
    required Map<String, dynamic> shippingAddress,
    String paymentMethod = 'COD',
    String? notes,
  }) {
    return {
      'items': _items
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                'color': item.selectedColor,
                'size': item.selectedSize,
              })
          .toList(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
