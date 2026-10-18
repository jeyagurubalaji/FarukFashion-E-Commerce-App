const Product = require('../models/Product');
const Order = require('../models/Order');

exports.getRecommendations = async (req, res) => {
  try {
    const limit = Math.min(20, parseInt(req.query.limit) || 8);
    let preferredCategories = [];

    if (req.user) {
      preferredCategories = [...(req.user.preferredCategories || [])];
      const pastOrders = await Order.find({ userId: req.user._id }).limit(20);
      for (const order of pastOrders) {
        for (const item of order.items) {
          const p = await Product.findById(item.productId).select('category');
          if (p) preferredCategories.push(p.category);
        }
      }
      preferredCategories = [...new Set(preferredCategories)];
    }

    let products = [];
    if (preferredCategories.length) {
      products = await Product.find({
        active: true,
        category: { $in: preferredCategories },
      })
        .limit(limit)
        .sort({ featured: -1, createdAt: -1 });
    }

    if (products.length < limit) {
      const featured = await Product.find({ active: true, featured: true })
        .limit(limit)
        .sort({ createdAt: -1 });
      const ids = new Set(products.map((p) => String(p._id)));
      for (const p of featured) {
        if (!ids.has(String(p._id))) products.push(p);
      }
    }

    res.json({ success: true, data: products.slice(0, limit) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
