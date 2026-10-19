import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';

// Web-only JS interop (ignored on mobile builds via conditional use)
import 'payment_web_helper.dart'
    if (dart.library.io) 'payment_web_helper_stub.dart' as web_pay;

class PaymentService {
  final ApiService _api = ApiService();
  Razorpay? _razorpay;

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  Future<bool> startRazorpayCheckout({
    required String internalOrderId,
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    try {
      final rzp = await _api.createRazorpayOrder(internalOrderId);

      final keyId = (rzp['keyId'] ?? '').toString();
      final razorpayOrderId = (rzp['razorpayOrderId'] ?? '').toString();
      final amount = (rzp['amount'] as num?)?.toInt() ?? 0;
      final orderNumber = (rzp['orderNumber'] ?? '').toString();

      if (keyId.isEmpty || razorpayOrderId.isEmpty || amount <= 0) {
        throw Exception('Invalid Razorpay order response');
      }

      if (kIsWeb) {
        return web_pay.openRazorpayWeb(
          api: _api,
          context: context,
          internalOrderId: internalOrderId,
          keyId: keyId,
          razorpayOrderId: razorpayOrderId,
          amount: amount,
          orderNumber: orderNumber,
          customerName: customerName,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
        );
      }

      return _openMobile(
        context: context,
        internalOrderId: internalOrderId,
        keyId: keyId,
        razorpayOrderId: razorpayOrderId,
        amount: amount,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _openMobile({
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
    _razorpay ??= Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
      try {
        await _api.verifyPayment({
          'orderId': internalOrderId,
          'razorpayOrderId': r.orderId ?? razorpayOrderId,
          'razorpayPaymentId': r.paymentId,
          'razorpaySignature': r.signature,
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
      } catch (_) {
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (!completer.isCompleted) completer.complete(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r.message ?? 'Payment cancelled or failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    _razorpay!.open({
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
    });

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => false,
    );
  }
}