import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/app_colors.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  ProductModel? _product;
  bool _loading = true;
  String? _selectedColor;
  String? _selectedSize;
  int _qty = 1;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _api.getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _product = p;
          if (p.colors.isNotEmpty) _selectedColor = p.colors.first;
          if (p.sizes.isNotEmpty) _selectedSize = p.sizes.first;
          _imageIndex = 0;
          _loading = false;
        });
        context.read<WishlistProvider>().remember(p);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToCart() {
    if (_product == null) return;
    final cart = context.read<CartProvider>();
    cart.addItem(
      _product!,
      color: _selectedColor,
      size: _selectedSize,
    );
    for (int i = 1; i < _qty; i++) {
      cart.addItem(
        _product!,
        color: _selectedColor,
        size: _selectedSize,
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  Widget _buildNetworkImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.charcoal,
        child: const Center(
          child: Icon(Icons.shopping_bag_outlined,
              color: AppColors.gold, size: 48),
        ),
      );
    }
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.charcoal,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.gold,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.charcoal,
        child: const Center(
          child: Icon(Icons.image_not_supported,
              color: AppColors.textMuted, size: 40),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final p = _product;
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(title: const Text('Product')),
        body: const Center(
          child: Text('Product not found',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final images = p.resolvedImageUrls;
    final mainUrl = images.isNotEmpty
        ? images[_imageIndex.clamp(0, images.length - 1)]
        : p.primaryImage;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppColors.deepBlack,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.gold),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wish, _) {
                  final on = wish.contains(p.id);
                  return IconButton(
                    icon: Icon(
                      on ? Icons.favorite : Icons.favorite_border,
                      color: on ? Colors.redAccent : AppColors.gold,
                    ),
                    onPressed: () {
                      wish.toggle(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(on
                              ? 'Removed from wishlist'
                              : 'Added to wishlist'),
                          backgroundColor: AppColors.gold,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildNetworkImage(mainUrl),
            ),
          ),
          if (images.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == _imageIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _imageIndex = i),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selected ? AppColors.gold : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildNetworkImage(images[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${p.displayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          '₹${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.inStock
                        ? 'In Stock (${p.stockQuantity} left)'
                        : 'Out of Stock',
                    style: TextStyle(
                      color: p.inStock ? AppColors.success : AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                  if (p.description != null &&
                      p.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      p.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (p.colors.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('Color',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: p.colors.map((c) {
                        final sel = c == _selectedColor;
                        return ChoiceChip(
                          label: Text(c),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _selectedColor = c),
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: sel ? AppColors.black : AppColors.white,
                          ),
                          backgroundColor: AppColors.cardBg,
                        );
                      }).toList(),
                    ),
                  ],
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Size',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: p.sizes.map((s) {
                        final sel = s == _selectedSize;
                        return ChoiceChip(
                          label: Text(s),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _selectedSize = s),
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: sel ? AppColors.black : AppColors.white,
                          ),
                          backgroundColor: AppColors.cardBg,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _qty > 1
                                  ? () => setState(() => _qty--)
                                  : null,
                            ),
                            Text(
                              '$_qty',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: p.inStock ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'ADD TO CART',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}