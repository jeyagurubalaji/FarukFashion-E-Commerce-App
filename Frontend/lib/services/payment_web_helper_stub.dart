import 'package:flutter/material.dart';
import 'api_service.dart';

Future<bool> openRazorpayWeb({
  required ApiService api,
  required BuildContext context,
  required String internalOrderId,
  required String keyId,
  required String razorpayOrderId,
  required int amount,
  required String orderNumber,
  required String customerName,
  required String customerPhone,
  required String customerEmail,
}) async {
  throw UnsupportedError('Web Razorpay only');
}