import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  String? selectedColor;
  String? selectedSize;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedColor,
    this.selectedSize,
  });

  double get total => product.displayPrice * quantity;
}
