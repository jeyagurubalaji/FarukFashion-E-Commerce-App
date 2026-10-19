import 'dart:async';
import 'dart:js_util' as js_util;
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
  final completer = Completer<bool>();

  void onSuccess(dynamic response) async {
    try {
      await api.verifyPayment({
        'orderId': internalOrderId,
        'razorpayOrderId':
            js_util.getProperty(response, 'razorpay_order_id')?.toString(),
        'razorpayPaymentId':
            js_util.getProperty(response, 'razorpay_payment_id')?.toString(),
        'razorpaySignature':
            js_util.getProperty(response, 'razorpay_signature')?.toString(),
      });
      if (!completer.isCompleted) completer.complete(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful · Order confirmed'),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
      }
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void onDismiss() {
    if (!completer.isCompleted) completer.complete(false);
  }

  final options = js_util.jsify({
    'key': keyId,
    'amount': amount,
    'currency': 'INR',
    'name': 'Faruk Fashion',
    'description': 'Order $orderNumber',
    'order_id': razorpayOrderId,
    'prefill': {
      'name': customerName,
      'contact': customerPhone,
      'email': customerEmail,
    },
    'theme': {'color': '#D4AF37'},
    'handler': js_util.allowInterop(onSuccess),
    'modal': {
      'ondismiss': js_util.allowInterop(onDismiss),
    },
  });

  final razorpayCtor = js_util.getProperty(js_util.globalThis, 'Razorpay');
  if (razorpayCtor == null) {
    throw Exception(
      'Razorpay script missing. Add checkout.js in web/index.html and hard-refresh.',
    );
  }

  final instance = js_util.callConstructor(razorpayCtor, [options]);
  js_util.callMethod(instance, 'open', []);

  return completer.future.timeout(
    const Duration(minutes: 10),
    onTimeout: () => false,
  );
}