const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Offer = require('../models/Offer');
const ReturnRefundLog = require('../models/ReturnRefundLog');

exports.dashboard = async (req, res) => {
  try {
    const [
      totalProducts,
      activeProducts,
      totalOrders,
      pendingOrders,
      totalCustomers,
      totalOffers,
      revenueAgg,
      recentOrders,
      lowStock,
    ] = await Promise.all([
      Product.countDocuments(),
      Product.countDocuments({ active: true }),
      Order.countDocuments(),
      Order.countDocuments({ status: { $in: ['PLACED', 'CONFIRMED', 'PACKED'] } }),
      User.countDocuments({ roles: 'ROLE_CUSTOMER' }),
      Offer.countDocuments({ active: true }),
      Order.aggregate([
        { $match: { paymentStatus: { $in: ['PAID', 'PENDING'] }, status: { $ne: 'CANCELLED' } } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } },
      ]),
      Order.find().sort({ createdAt: -1 }).limit(8),
      Product.find({
        active: true,
        $expr: { $lte: ['$stockQuantity', '$lowStockThreshold'] },
      }).limit(10),
    ]);

    res.json({
      success: true,
      data: {
        totalProducts,
        activeProducts,
        totalOrders,
        pendingOrders,
        totalCustomers,
        totalOffers,
        totalRevenue: revenueAgg[0]?.total || 0,
        recentOrders,
        lowStock,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.listCustomers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 50;
    // All users (customers + admin), same as website
    const filter = {};
    if (req.query.q) {
      filter.$or = [
        { fullName: new RegExp(req.query.q, 'i') },
        { email: new RegExp(req.query.q, 'i') },
        { username: new RegExp(req.query.q, 'i') },
        { phone: new RegExp(req.query.q, 'i') },
      ];
    }
    const [content, total] = await Promise.all([
      User.find(filter).select('-password').sort({ createdAt: -1 }).skip(page * size).limit(size),
      User.countDocuments(filter),
    ]);
    res.json({ success: true, data: { content, totalElements: total, number: page, size } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.toggleCustomer = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.active = !user.active;
    await user.save();
    res.json({
      success: true,
      message: user.active ? 'User activated' : 'User deactivated',
      data: user,
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

/** Update customer — body values from client, nothing hardcoded */
exports.updateCustomer = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const {
      fullName,
      firstName,
      lastName,
      phone,
      address,
      city,
      state,
      pincode,
      preferredCategories,
      active,
    } = req.body;

    if (fullName != null) {
      user.fullName = String(fullName).trim();
    } else if (firstName != null || lastName != null) {
      const first = (firstName ?? '').toString().trim();
      const last = (lastName ?? '').toString().trim();
      user.fullName = `${first} ${last}`.trim() || user.fullName;
    }
    if (phone != null) user.phone = String(phone).trim();
    if (address != null) user.address = String(address).trim();
    if (city != null) user.city = String(city).trim();
    if (state != null) user.state = String(state).trim();
    if (pincode != null) user.pincode = String(pincode).trim();
    if (Array.isArray(preferredCategories)) {
      user.preferredCategories = preferredCategories
        .map((c) => String(c).trim())
        .filter(Boolean);
    }
    if (typeof active === 'boolean') user.active = active;

    await user.save();
    const safe = user.toObject();
    delete safe.password;
    res.json({ success: true, message: 'Customer updated', data: safe });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

/** Permanently delete customer */
exports.deleteCustomer = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (req.user && String(req.user._id) === String(user._id)) {
      return res.status(400).json({ success: false, message: 'Cannot delete your own account' });
    }

    const isAdmin = (user.roles || []).includes('ROLE_ADMIN');
    if (isAdmin) {
      const adminCount = await User.countDocuments({ roles: 'ROLE_ADMIN' });
      if (adminCount <= 1) {
        return res.status(400).json({ success: false, message: 'Cannot delete the last admin' });
      }
    }

    await User.findByIdAndDelete(user._id);
    res.json({ success: true, message: 'Customer deleted' });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.returnsList = async (req, res) => {
  try {
    const content = await ReturnRefundLog.find().sort({ requestedAt: -1 }).limit(50);
    res.json({ success: true, data: content });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};