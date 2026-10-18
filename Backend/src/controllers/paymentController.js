const Razorpay = require('razorpay');
const crypto = require('crypto');
const Order = require('../models/Order');
const notificationService = require('../services/notificationService');

function getRazorpay() {
  return new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
}

exports.createPayment = async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (!process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY_ID.includes('XXX')) {
      return res.status(400).json({
        success: false,
        message: 'Razorpay keys not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET',
      });
    }

    const amountPaise = Math.round(order.totalAmount * 100);
    const rzpOrder = await getRazorpay().orders.create({
      amount: amountPaise,
      currency: 'INR',
      receipt: order.orderNumber,
      payment_capture: 1,
    });

    order.paymentId = rzpOrder.id;
    order.paymentMethod = 'RAZORPAY';
    order.paymentStatus = 'PENDING';
    await order.save();

    res.json({
      success: true,
      message: 'Razorpay order created',
      data: {
        razorpayOrderId: rzpOrder.id,
        amount: amountPaise,
        currency: 'INR',
        keyId: process.env.RAZORPAY_KEY_ID,
        orderNumber: order.orderNumber,
        internalOrderId: order._id,
      },
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.verifyPayment = async (req, res) => {
  try {
    const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    const body = `${razorpayOrderId}|${razorpayPaymentId}`;
    const expected = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (expected !== razorpaySignature) {
      order.paymentStatus = 'FAILED';
      await order.save();
      return res.status(400).json({ success: false, message: 'Payment signature verification failed' });
    }

    order.paymentId = razorpayPaymentId;
    order.paymentStatus = 'PAID';
    order.status = 'CONFIRMED';
    await order.save();

    notificationService.sendOrderConfirmation(order).catch(console.error);
    notificationService.sendOrderStatusUpdate(order).catch(console.error);

    res.json({ success: true, message: 'Payment successful', data: order });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.confirmCod = async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    order.paymentMethod = 'COD';
    order.paymentStatus = 'PENDING';
    order.status = 'CONFIRMED';
    await order.save();

    notificationService.sendOrderConfirmation(order).catch(console.error);
    res.json({ success: true, message: 'COD order confirmed', data: order });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};
