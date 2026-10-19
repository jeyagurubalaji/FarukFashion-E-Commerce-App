import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  String _payMethod = 'RAZORPAY';
  bool _processing = false;
  final _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

    Future<void> _pay() async {
      if (!_formKey.currentState!.validate()) return;
      final cart = context.read<CartProvider>();
      if (cart.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty')),
        );
        return;
      }

      setState(() => _processing = true);

      try {
        // 1) place order (use line1/line2 for backend)
        final orderData = await ApiService().placeOrder({
          'items': cart.items
              .map((e) => {
                    'productId': e.product.id,
                    'quantity': e.quantity,
                    'color': e.selectedColor,
                    'size': e.selectedSize,
                  })
              .toList(),
          'shippingAddress': {
            'line1': _addr1Ctrl.text.trim(),
            'line2': _addr2Ctrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'state': _stateCtrl.text.trim(),
            'pincode': _pincodeCtrl.text.trim(),
          },
          'paymentMethod': _payMethod,
          'notes': null,
        });

        final orderId =
            (orderData['id'] ?? orderData['_id'] ?? '').toString();
        if (orderId.isEmpty) throw Exception('Order not created');

        // 2) COD
        if (_payMethod == 'COD') {
          cart.clear();
          if (!mounted) return;
          setState(() => _processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed · Cash on Delivery'),
              backgroundColor: AppColors.gold,
            ),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }

                // 3) Razorpay — stop spinner so UI feels instant, then open modal
                if (mounted) setState(() => _processing = false);

                final ok = await _paymentService.startRazorpayCheckout(
                  internalOrderId: orderId,
                  context: context,
                  customerName: _nameCtrl.text.trim(),
                  customerPhone: _phoneCtrl.text.trim(),
                  customerEmail: _emailCtrl.text.trim(),
                );

                if (ok && mounted) {
                  cart.clear();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                } else if (mounted) {
          setState(() => _processing = false);
          // Cart stays — user can retry
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.totalAmount;
    final gst = subtotal * 0.18;
    final total = subtotal + gst;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.deepBlack,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _field(_nameCtrl, 'Full name', required: true),
            _field(_phoneCtrl, 'Phone',
                required: true, keyboard: TextInputType.phone),
            _field(_emailCtrl, 'Email',
                keyboard: TextInputType.emailAddress),
            _field(_addr1Ctrl, 'Address line 1', required: true),
            _field(_addr2Ctrl, 'Address line 2'),
            Row(
              children: [
                Expanded(child: _field(_cityCtrl, 'City', required: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_stateCtrl, 'State', required: true)),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_pincodeCtrl, 'Pincode',
                      required: true, keyboard: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Method',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            RadioListTile<String>(
              value: 'RAZORPAY',
              groupValue: _payMethod,
              activeColor: AppColors.gold,
              title: const Text(
                'Online (Razorpay – UPI / Card / NetBanking)',
                style: TextStyle(color: AppColors.white, fontSize: 13),
              ),
              onChanged:
                  _processing ? null : (v) => setState(() => _payMethod = v!),
            ),
            RadioListTile<String>(
              value: 'COD',
              groupValue: _payMethod,
              activeColor: AppColors.gold,
              title: const Text(
                'Cash on Delivery',
                style: TextStyle(color: AppColors.white, fontSize: 13),
              ),
              onChanged:
                  _processing ? null : (v) => setState(() => _payMethod = v!),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                                    ...cart.items.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${e.product.name} ×${e.quantity}',
                                                style: const TextStyle(
                                                    color: AppColors.white, fontSize: 13),
                                              ),
                                            ),
                                            Text(
                                              '₹${(e.product.displayPrice * e.quantity).toStringAsFixed(0)}',
                                              style: const TextStyle(color: AppColors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                  const Divider(color: AppColors.border),
                  _row('Subtotal', subtotal),
                  _row('GST', gst),
                  _row('Total', total, bold: true),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processing ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _processing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.black,
                              ),
                            )
                          : const Text(
                              'PAY SECURELY',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure payment · Order confirmation via WhatsApp, SMS & Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.gold : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: bold ? AppColors.gold : AppColors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}