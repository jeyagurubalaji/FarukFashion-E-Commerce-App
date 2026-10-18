const Order = require('../models/Order');
const Product = require('../models/Product');
const PurchaseLog = require('../models/PurchaseLog');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

function generateOrderNumber() {
  const d = new Date();
  const datePart = d.toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.floor(1000 + Math.random() * 9000);
  return `FF-${datePart}-${random}`;
}

exports.placeOrder = async (req, res) => {
  try {
    const user = req.user;
    const { items, shippingAddress, paymentMethod = 'COD', notes } = req.body;

    if (!items?.length) {
      return res.status(400).json({ success: false, message: 'Cart is empty' });
    }

    const orderItems = [];
    let subTotal = 0;

    for (const item of items) {
      const product = await Product.findById(item.productId);
      if (!product || !product.active) {
        return res.status(400).json({ success: false, message: `Product not available: ${item.productId}` });
      }
      if (product.stockQuantity < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock for ${product.name}. Available: ${product.stockQuantity}`,
        });
      }

      const unitPrice = product.discountPrice != null ? product.discountPrice : product.price;
      const totalPrice = unitPrice * item.quantity;
      subTotal += totalPrice;

      orderItems.push({
        productId: product._id,
        productName: product.name,
        imageUrl: product.imageUrls?.[0],
        color: item.color,
        size: item.size,
        quantity: item.quantity,
        unitPrice,
        totalPrice,
      });

      product.stockQuantity -= item.quantity;
      await product.save();
    }

    const shippingCharge = subTotal > 999 ? 0 : 49;
    const taxAmount = Math.round(subTotal * 0.05 * 100) / 100;
    const totalAmount = subTotal + shippingCharge + taxAmount;
    const orderNumber = generateOrderNumber();

    const order = await Order.create({
      orderNumber,
      userId: user._id,
      customerName: user.fullName,
      customerPhone: user.phone,
      customerEmail: user.email,
      shippingAddress,
      items: orderItems,
      subTotal,
      shippingCharge,
      taxAmount,
      totalAmount,
      paymentMethod,
      paymentStatus: 'PENDING',
      status: 'PLACED',
      notes,
    });

    await PurchaseLog.create({
      orderId: order._id,
      userId: user._id,
      orderNumber,
      totalAmount,
      paymentMethod,
      paymentStatus: 'PENDING',
      itemCount: orderItems.length,
    });

    // Update preferences for recommendations
    const cats = new Set(user.preferredCategories || []);
    for (const oi of orderItems) {
      const p = await Product.findById(oi.productId);
      if (p) cats.add(p.category);
    }
    user.preferredCategories = [...cats];
    await user.save({ validateBeforeSave: false });

    if (String(paymentMethod).toUpperCase() === 'COD') {
      notificationService.sendOrderConfirmation(order).catch(console.error);
    }

    res.status(201).json({
      success: true,
      message: 'Order placed successfully',
      data: order,
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.myOrders = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 10;
    const [content, total] = await Promise.all([
      Order.find({ userId: req.user._id })
        .sort({ createdAt: -1 })
        .skip(page * size)
        .limit(size),
      Order.countDocuments({ userId: req.user._id }),
    ]);
    res.json({
      success: true,
      data: { content, totalElements: total, number: page, size },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getByNumber = async (req, res) => {
  try {
    const order = await Order.findOne({ orderNumber: req.params.orderNumber });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.allOrders = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 20;
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const [content, total] = await Promise.all([
      Order.find(filter).sort({ createdAt: -1 }).skip(page * size).limit(size),
      Order.countDocuments(filter),
    ]);
    res.json({
      success: true,
      data: { content, totalElements: total, number: page, size },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const status = req.query.status || req.body.status;
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    order.status = status;
    if (status === 'DELIVERED') order.deliveredAt = new Date();
    if (status === 'CANCELLED') {
      order.cancelledAt = new Date();
      for (const item of order.items) {
        await Product.findByIdAndUpdate(item.productId, {
          $inc: { stockQuantity: item.quantity },
        });
      }
    }
    await order.save();
    notificationService.sendOrderStatusUpdate(order).catch(console.error);

    res.json({ success: true, message: 'Order status updated', data: order });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.remove = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Restore stock if order was not already cancelled
    if (order.status !== 'CANCELLED') {
      for (const item of order.items || []) {
        if (item.productId) {
          await Product.findByIdAndUpdate(item.productId, {
            $inc: { stockQuantity: item.quantity || 0 },
          });
        }
      }
    }

    await Order.findByIdAndDelete(req.params.id);

    // Optional: clean purchase log
    try {
      await PurchaseLog.deleteMany({ orderId: order._id });
    } catch (_) {}

    res.json({ success: true, message: 'Order deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};