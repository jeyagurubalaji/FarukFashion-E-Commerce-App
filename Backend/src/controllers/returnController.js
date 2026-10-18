const ReturnRefundLog = require('../models/ReturnRefundLog');
const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

exports.requestReturn = async (req, res) => {
  try {
    const { orderId, productIds, reason, description } = req.body;
    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (String(order.userId) !== String(req.user._id)) {
      return res.status(403).json({ success: false, message: 'You can only return your own orders' });
    }

    let refundAmount = 0;
    for (const item of order.items) {
      if (productIds.map(String).includes(String(item.productId))) {
        refundAmount += item.totalPrice;
      }
    }

    const log = await ReturnRefundLog.create({
      orderId,
      userId: req.user._id,
      orderNumber: order.orderNumber,
      productIds,
      reason,
      description,
      status: 'REQUESTED',
      refundAmount,
    });

    order.status = 'RETURN_REQUESTED';
    await order.save();

    notificationService
      .sendReturnUpdate(req.user.phone, req.user.email, order.orderNumber, 'REQUESTED')
      .catch(console.error);

    res.status(201).json({ success: true, message: 'Return request submitted', data: log });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.myReturns = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 10;
    const [content, total] = await Promise.all([
      ReturnRefundLog.find({ userId: req.user._id })
        .sort({ requestedAt: -1 })
        .skip(page * size)
        .limit(size),
      ReturnRefundLog.countDocuments({ userId: req.user._id }),
    ]);
    res.json({ success: true, data: { content, totalElements: total } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.allReturns = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 20;
    const [content, total] = await Promise.all([
      ReturnRefundLog.find().sort({ requestedAt: -1 }).skip(page * size).limit(size),
      ReturnRefundLog.countDocuments(),
    ]);
    res.json({ success: true, data: { content, totalElements: total } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const status = req.query.status || req.body.status;
    const refundTransactionId = req.query.refundTransactionId || req.body.refundTransactionId;
    const entry = await ReturnRefundLog.findById(req.params.id);
    if (!entry) return res.status(404).json({ success: false, message: 'Return not found' });

    entry.status = status;

    if (status === 'REFUNDED') {
      entry.refundTransactionId = refundTransactionId;
      entry.refundMethod = 'ORIGINAL_PAYMENT';
      entry.processedAt = new Date();

      const order = await Order.findById(entry.orderId);
      if (order) {
        for (const pid of entry.productIds) {
          const item = order.items.find((i) => String(i.productId) === String(pid));
          if (item) {
            await Product.findByIdAndUpdate(pid, { $inc: { stockQuantity: item.quantity } });
          }
        }
        order.status = 'REFUNDED';
        order.paymentStatus = 'REFUNDED';
        await order.save();
      }
    }

    await entry.save();

    const user = await User.findById(entry.userId);
    if (user) {
      notificationService
        .sendReturnUpdate(user.phone, user.email, entry.orderNumber, status)
        .catch(console.error);
    }

    res.json({ success: true, message: 'Return status updated', data: entry });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};
