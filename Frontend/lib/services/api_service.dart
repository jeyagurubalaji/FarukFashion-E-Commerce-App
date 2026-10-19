import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Something went wrong');
  }

  // ========== AUTH ==========
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = await _handleResponse(response);
    return data['data'];
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = await _handleResponse(response);
    return data['data'];
  }

    Future<Map<String, dynamic>> googleLogin({
      String? idToken,
      String? accessToken,
      String? email,
      String? displayName,
    }) async {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/google'),
        headers: _headers,
        body: jsonEncode({
          if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
          if (accessToken != null && accessToken.isNotEmpty)
            'accessToken': accessToken,
          if (email != null) 'email': email,
          if (displayName != null) 'fullName': displayName,
        }),
      );
      final data = await _handleResponse(response);
      return Map<String, dynamic>.from(data['data'] as Map);
    }

        Future<Map<String, dynamic>> forgotPassword(String emailOrUsername) async {
          final response = await http.post(
            Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({
              'email': emailOrUsername,
              'username': emailOrUsername,
            }),
          );
          final data = await _handleResponse(response);
          return {
            'message': data['message']?.toString() ?? 'OTP sent',
            'emailHint': data['data']?['emailHint'],
          };
        }

        Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
          final response = await http.post(
            Uri.parse('${AppConstants.baseUrl}/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode({'email': email.trim(), 'otp': otp.trim()}),
          );
          final data = await _handleResponse(response);
          return Map<String, dynamic>.from(data['data'] as Map? ?? {});
        }

        Future<String> resetPassword(String token, String password) async {
          final response = await http.post(
            Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
            headers: _headers,
            body: jsonEncode({'token': token, 'password': password}),
          );
          final data = await _handleResponse(response);
          return data['message']?.toString() ?? 'Password updated.';
        }

  // ========== PRODUCTS ==========
  Future<List<ProductModel>> getProducts({
    int page = 0,
    int size = 12,
    String? category,
    String? search,
  }) async {
    String url = '${AppConstants.baseUrl}/products?page=$page&size=$size';
    if (category != null) {
      url = '${AppConstants.baseUrl}/products/category/$category?page=$page&size=$size';
    } else if (search != null && search.isNotEmpty) {
      url = '${AppConstants.baseUrl}/products/search?q=$search&page=$page&size=$size';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);
    final data = await _handleResponse(response);
    final content = data['data']['content'] as List<dynamic>? ?? [];
    return content.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/products/featured?size=8'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final content = data['data']['content'] as List<dynamic>? ?? [];
    return content.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/products/$id'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return ProductModel.fromJson(data['data']);
  }

  // ========== ORDERS ==========
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/orders'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = await _handleResponse(response);
    return data['data'];
  }

  Future<List<dynamic>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/orders/my'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return data['data']['content'] as List<dynamic>? ?? [];
  }

  // ========== PAYMENTS ==========
  Future<Map<String, dynamic>> createRazorpayOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/payments/create/$orderId'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/payments/verify'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = await _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

    Future<Map<String, dynamic>> confirmCod(String orderId) async {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payments/cod/confirm/$orderId'),
        headers: _headers,
      );
      final data = await _handleResponse(response);
      return Map<String, dynamic>.from(data['data'] as Map? ?? data);
    }

  // ========== RETURNS ==========
  Future<Map<String, dynamic>> requestReturn(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/returns'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = await _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyReturns() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/returns/my'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return data['data']['content'] as List<dynamic>? ?? [];
  }

  // ========== RECOMMENDATIONS ==========
  Future<List<ProductModel>> getRecommendations({int limit = 8}) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/recommendations?limit=$limit'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  // ========== OFFERS / BANNERS ==========
  Future<List<Map<String, dynamic>>> getHomeBanners() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/offers/banners'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ========== ADMIN ==========
  Future<Map<String, dynamic>> adminDashboard() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/admin/dashboard'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<List<dynamic>> adminOrders({int page = 0, String? status}) async {
    var url = '${AppConstants.baseUrl}/admin/orders?page=$page&size=50';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    final data = await _handleResponse(response);
    return data['data']['content'] as List<dynamic>? ?? [];
  }

  Future<void> adminUpdateOrderStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/admin/orders/$id/status?status=$status'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

    Future<void> adminDeleteOrder(String id) async {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/admin/orders/$id'),
        headers: _headers,
      );
      await _handleResponse(response);
    }

  Future<List<ProductModel>> adminAllProducts({int page = 0}) async {
    // reuse public list; admin can also create/update
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/products?page=$page&size=50'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final content = data['data']['content'] as List<dynamic>? ?? [];
    return content.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> adminCreateProduct(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/admin/products'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<Map<String, dynamic>> adminUpdateProduct(String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/admin/products/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<void> adminUpdateStock(String id, int quantity) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/admin/products/$id/stock?quantity=$quantity'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  Future<void> adminDeactivateProduct(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/admin/products/$id'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

    Future<List<dynamic>> adminCustomers({int page = 0}) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/admin/customers?page=$page&size=50'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return data['data']['content'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> adminUpdateCustomer(
      String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/admin/customers/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<void> adminDeleteCustomer(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/admin/customers/$id'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  Future<void> adminToggleCustomer(String id) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/admin/customers/$id/toggle'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> adminOffers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/offers/admin/all'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> adminToggleOffer(String id) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/offers/admin/$id/toggle'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> adminCreateOffer(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/offers/admin'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }
    Future<Map<String, dynamic>> adminUpdateOffer(
      String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/offers/admin/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<void> adminDeleteOffer(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/offers/admin/$id'),
      headers: _headers,
    );
    await _handleResponse(response);
  }
    Future<List<String>> adminUploadImages(List<Map<String, dynamic>> files) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/admin/upload');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    for (final f in files) {
      var name = (f['name'] as String?) ?? 'image.jpg';
      final lower = name.toLowerCase();
      if (!lower.endsWith('.jpg') &&
          !lower.endsWith('.jpeg') &&
          !lower.endsWith('.png') &&
          !lower.endsWith('.webp') &&
          !lower.endsWith('.gif')) {
        name = '$name.jpg';
      }
      final bytes = f['bytes'] as List<int>?;
      final path = f['path'] as String?;
      final mediaType = MediaType('image', 'jpeg');
      if (bytes != null && bytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: name,
          contentType: mediaType,
        ));
      } else if (path != null && path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          path,
          contentType: mediaType,
        ));
      }
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = await _handleResponse(response);
    final urls = (data['data']['urls'] as List<dynamic>?) ?? [];
    return urls.map((e) => e.toString()).toList();
  }
}
