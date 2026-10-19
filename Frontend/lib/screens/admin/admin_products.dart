import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<ProductModel> _products = [];
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
      final list = await ApiService().adminAllProducts();
      if (mounted) {
        setState(() {
          _products = list;
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

  Future<void> _openForm({ProductModel? product}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductFormSheet(product: product),
    );
    if (result == true) _load();
  }

  Future<void> _delete(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Deactivate product?',
            style: TextStyle(color: AppColors.white)),
        content:
            Text(p.name, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService().adminDeactivateProduct(p.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deactivated')),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
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
        label: const Text('ADD PRODUCT',
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
                  child: _products.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No products yet.\nTap ADD PRODUCT to create one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final p = _products[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.gold.withOpacity(0.12)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    color: AppColors.charcoal,
                                    child: p.primaryImage.isNotEmpty
                                        ? Image.network(
                                            p.primaryImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                              child: Text('FF',
                                                  style: TextStyle(
                                                      color: AppColors.gold,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          )
                                        : const Center(
                                            child: Text('FF',
                                                style: TextStyle(
                                                    color: AppColors.gold,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.category.replaceAll('_', ' ')} · ${p.targetAudience}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (p.hasDiscount) ...[
                                            Text(
                                              '₹${p.displayPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: AppColors.gold,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '₹${p.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              '₹${p.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: AppColors.gold,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Stock ${p.stockQuantity}',
                                            style: TextStyle(
                                              color: p.stockQuantity <=
                                                      p.lowStockThreshold
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.active
                                                  ? AppColors.gold
                                                      .withOpacity(0.2)
                                                  : AppColors.error
                                                      .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              p.active ? 'ACTIVE' : 'OFF',
                                              style: TextStyle(
                                                color: p.active
                                                    ? AppColors.gold
                                                    : AppColors.error,
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
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.gold, size: 20),
                                      onPressed: () =>
                                          _openForm(product: p),
                                    ),
                                    IconButton(
                                      tooltip: 'Deactivate',
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 20),
                                      onPressed: () => _delete(p),
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

class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  const _ProductFormSheet({this.product});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _gst;
  late final TextEditingController _stock;
  late final TextEditingController _lowStock;
  late final TextEditingController _colors;
  late final TextEditingController _sizes;
  late final TextEditingController _tags;
  late final TextEditingController _imageUrl;

  String _category = 'HANDBAGS';
  String _audience = 'Women';
  bool _featured = false;
  bool _active = true;
  bool _saving = false;
  bool _uploading = false;
  final List<String> _uploadedUrls = [];

  /// Only permanent https URLs (Cloudinary). Never keep /api/uploads.
  static String? _sanitizeUrl(String? raw) {
    if (raw == null) return null;
    var u = raw.trim();
    if (u.isEmpty) return null;
    if (u.contains('/api/uploads/')) return null;
    if (u.startsWith('http://')) {
      u = u.replaceFirst('http://', 'https://');
    }
    if (!u.startsWith('https://')) return null;
    return u;
  }

  static List<String> _sanitizeList(Iterable<String> urls) {
    final out = <String>[];
    for (final raw in urls) {
      final u = _sanitizeUrl(raw);
      if (u != null && !out.contains(u)) out.add(u);
    }
    return out;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final payload = <Map<String, dynamic>>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        payload.add({
          'path': f.path.isNotEmpty ? f.path : null,
          'bytes': bytes,
          'name': f.name.isNotEmpty ? f.name : 'image.jpg',
        });
      }
      final urls = _sanitizeList(await ApiService().adminUploadImages(payload));
      if (urls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upload did not return a permanent Cloudinary URL. Check backend Cloudinary env.',
              ),
            ),
          );
        }
        return;
      }
      setState(() {
        for (final u in urls) {
          if (!_uploadedUrls.contains(u)) _uploadedUrls.add(u);
        }
        if (_imageUrl.text.trim().isEmpty) {
          _imageUrl.text = urls.first;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${urls.length} permanent image(s) uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  static const audiences = ['Women', 'Men', 'Kids', 'Unisex'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _discount = TextEditingController(
        text: p?.discountPrice != null
            ? p!.discountPrice!.toStringAsFixed(0)
            : '');
    _gst = TextEditingController(
        text: (p?.gstPercent ?? 18).toStringAsFixed(0));
    _stock = TextEditingController(text: '${p?.stockQuantity ?? 10}');
    _lowStock =
        TextEditingController(text: '${p?.lowStockThreshold ?? 5}');
    _colors = TextEditingController(text: p?.colors.join(', ') ?? '');
    _sizes = TextEditingController(text: p?.sizes.join(', ') ?? '');
    _tags = TextEditingController(text: p?.tags.join(', ') ?? '');

    final existing = _sanitizeList(p?.imageUrls ?? const []);
    _uploadedUrls.addAll(existing);
    _imageUrl = TextEditingController(
      text: existing.isNotEmpty ? existing.first : '',
    );

    if (p != null) {
      _category = p.category;
      _audience = p.targetAudience;
      _featured = p.featured;
      _active = p.active;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _gst.dispose();
    _stock.dispose();
    _lowStock.dispose();
    _colors.dispose();
    _sizes.dispose();
    _tags.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // MAIN = typed URL first, then other permanent uploads
    final imageUrls = <String>[];
    final typed = _sanitizeUrl(_imageUrl.text);
    if (typed != null) imageUrls.add(typed);
    for (final u in _sanitizeList(_uploadedUrls)) {
      if (!imageUrls.contains(u)) imageUrls.add(u);
    }

    if (imageUrls.isEmpty) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Add a permanent image: upload via Cloudinary or paste https://res.cloudinary.com/... URL',
            ),
          ),
        );
      }
      return;
    }

    final body = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'category': _category,
      'targetAudience': _audience,
      'price': double.tryParse(_price.text) ?? 0,
      'discountPrice': _discount.text.trim().isEmpty
          ? null
          : double.tryParse(_discount.text),
      'gstPercent': double.tryParse(_gst.text) ?? 18,
      'stockQuantity': int.tryParse(_stock.text) ?? 0,
      'lowStockThreshold': int.tryParse(_lowStock.text) ?? 5,
      'colors': _splitCsv(_colors.text),
      'sizes': _splitCsv(_sizes.text),
      'tags': _splitCsv(_tags.text),
      'imageUrls': imageUrls,
      'featured': _featured,
      'active': _active,
    };

    try {
      if (widget.product == null) {
        await ApiService().adminCreateProduct(body);
      } else {
        await ApiService().adminUpdateProduct(widget.product!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', ''))),
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
    final isEdit = widget.product != null;

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
                isEdit ? 'Edit Product' : 'Add Product',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                style: const TextStyle(color: AppColors.white),
                decoration: _dec('NAME *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                style: const TextStyle(color: AppColors.white),
                maxLines: 3,
                decoration: _dec('DESCRIPTION'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppColors.charcoal,
                      decoration: _dec('CATEGORY *'),
                      style:
                          const TextStyle(color: AppColors.white, fontSize: 14),
                      items: AppConstants.productCategories
                          .map((c) => DropdownMenuItem(
                                value: c['code'],
                                child: Text(c['name']!,
                                    style: const TextStyle(
                                        color: AppColors.white)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: audiences.contains(_audience)
                          ? _audience
                          : 'Unisex',
                      dropdownColor: AppColors.charcoal,
                      decoration: _dec('TARGET AUDIENCE'),
                      style:
                          const TextStyle(color: AppColors.white, fontSize: 14),
                      items: audiences
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a,
                                    style: const TextStyle(
                                        color: AppColors.white)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _audience = v ?? _audience),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('PRICE (₹) *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('DISCOUNT PRICE (₹)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gst,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('GST % *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('STOCK QUANTITY *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lowStock,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.white),
                decoration: _dec('LOW STOCK ALERT AT'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colors,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('COLORS (COMMA SEPARATED)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sizes,
                      style: const TextStyle(color: AppColors.white),
                      decoration: _dec('SIZES (COMMA SEPARATED)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                style: const TextStyle(color: AppColors.white),
                decoration: _dec('TAGS (COMMA SEPARATED)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'PRODUCT IMAGE',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(
                        _uploading ? 'UPLOADING...' : 'UPLOAD IMAGE'),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'or paste URL below',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              if (_uploadedUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final url = _uploadedUrls[i];
                      final isMain = _imageUrl.text.trim() == url ||
                          (_imageUrl.text.trim().isEmpty && i == 0);
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _imageUrl.text = url),
                            child: Container(
                              width: 72,
                              height: 72,
                              margin:
                                  const EdgeInsets.only(top: 8, right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMain
                                      ? AppColors.gold
                                      : AppColors.border,
                                  width: isMain ? 2.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image,
                                      color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _uploadedUrls.removeAt(i);
                                  if (_imageUrl.text.trim() == url) {
                                    _imageUrl.text =
                                        _uploadedUrls.isNotEmpty
                                            ? _uploadedUrls.first
                                            : '';
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                          if (isMain)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                color: AppColors.gold,
                                child: const Text(
                                  'MAIN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Select multiple files when uploading. Click a thumbnail to set main image.',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageUrl,
                style: const TextStyle(color: AppColors.white),
                decoration: _dec('PRODUCT IMAGE URL'),
                onChanged: (_) => setState(() {}),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Paste full URL: https://res.cloudinary.com/gqra2hnc/...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _featured,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _featured = v ?? false),
                  ),
                  const Text('Featured',
                      style: TextStyle(color: AppColors.white)),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _active,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _active = v ?? true),
                  ),
                  const Text('Active', style: TextStyle(color: AppColors.white)),
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
                              isEdit ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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