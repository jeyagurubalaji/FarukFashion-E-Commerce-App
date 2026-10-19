import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryCode;
  final String categoryName;

  const ProductListScreen({
    super.key,
    this.categoryCode,
    required this.categoryName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _api = ApiService();
  List<ProductModel> _products = [];
  bool _loading = true;
  int _page = 0;
  bool _hasMore = true;

  /// Empty or null = show all products (same as Home).
  String? get _categoryFilter {
    final c = widget.categoryCode?.trim();
    if (c == null || c.isEmpty) return null;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _loading = true;
        _page = 0;
      });
    }

    try {
      final list = await _api.getProducts(
        page: _page,
        size: 12,
        category: _categoryFilter, // null for "All"
      );
      if (mounted) {
        setState(() {
          if (loadMore) {
            _products.addAll(list);
          } else {
            _products = list;
          }
          _hasMore = list.length >= 12;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: _loading && _products.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () => _load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _products.length) {
                        _page++;
                        _load(loadMore: true);
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.gold),
                          ),
                        );
                      }
                      final p = _products[i];
                      return ProductCard(
                        product: p,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(productId: p.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}