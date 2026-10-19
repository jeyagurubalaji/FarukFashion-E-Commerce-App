import '../utils/constants.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? subCategory;
  final String targetAudience;
  final double price;
  final double? discountPrice;
  final int? discountPercent;
  final double gstPercent;
  final String brand;
  final List<String> colors;
  final List<String> sizes;
  final String? material;
  final List<String> imageUrls;
  final List<String> tags;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool active;
  final bool featured;
  final double averageRating;
  final int reviewCount;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.subCategory,
    this.targetAudience = 'Unisex',
    required this.price,
    this.discountPrice,
    this.discountPercent,
    this.gstPercent = 18,
    this.brand = 'Faruk Fashion',
    this.colors = const [],
    this.sizes = const [],
    this.material,
    this.imageUrls = const [],
    this.tags = const [],
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    this.active = true,
    this.featured = false,
    this.averageRating = 0,
    this.reviewCount = 0,
  });

  /// Keep permanent https images only. Drop temporary Vercel /api/uploads paths.
  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final List<String> raw = [];

    final list = json['imageUrls'];
    if (list is List) {
      for (final e in list) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) raw.add(s);
      }
    }

    // Some old records may store a single imageUrl
    final single = json['imageUrl']?.toString().trim();
    if (single != null && single.isNotEmpty && !raw.contains(single)) {
      raw.add(single);
    }

    final cleaned = <String>[];
    for (var u in raw) {
      if (u.contains('/api/uploads/')) continue;
      if (u.startsWith('http://')) {
        u = u.replaceFirst('http://', 'https://');
      }
      if (u.startsWith('https://')) {
        cleaned.add(u);
      }
    }
    return cleaned;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      targetAudience: json['targetAudience']?.toString() ?? 'Unisex',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 18,
      brand: json['brand'] ?? 'Faruk Fashion',
      colors: (json['colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      material: json['material'],
      imageUrls: _parseImageUrls(json),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      active: json['active'] ?? true,
      featured: json['featured'] ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  double get displayPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get inStock => stockQuantity > 0;

  static String resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var u = raw.trim();
    if (u.contains('/api/uploads/')) return '';
    if (u.startsWith('http://')) {
      u = u.replaceFirst('http://', 'https://');
    }
    if (u.startsWith('https://')) return u;
    return '';
  }

  String get primaryImage {
    if (imageUrls.isEmpty) return '';
    return resolveImageUrl(imageUrls.first);
  }

  List<String> get resolvedImageUrls =>
      imageUrls.map(resolveImageUrl).where((e) => e.isNotEmpty).toList();
}