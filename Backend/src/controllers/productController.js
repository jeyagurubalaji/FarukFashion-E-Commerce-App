const Product = require('../models/Product');

exports.getProducts = async (req, res) => {
  try {
    const page = Math.max(0, parseInt(req.query.page) || 0);
    const size = Math.min(50, parseInt(req.query.size) || 12);
    const filter = { active: true };

    if (req.query.category) filter.category = req.query.category;
    if (req.query.q) filter.$text = { $search: req.query.q };

    const [content, total] = await Promise.all([
      Product.find(filter)
        .sort({ createdAt: -1 })
        .skip(page * size)
        .limit(size),
      Product.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        content,
        totalElements: total,
        totalPages: Math.ceil(total / size),
        number: page,
        size,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getByCategory = async (req, res) => {
  req.query.category = req.params.category;
  return exports.getProducts(req, res);
};

exports.getFeatured = async (req, res) => {
  try {
    const size = parseInt(req.query.size) || 8;
    const content = await Product.find({ active: true, featured: true })
      .sort({ createdAt: -1 })
      .limit(size);
    res.json({
      success: true,
      data: { content, totalElements: content.length },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.search = async (req, res) => {
  req.query.q = req.query.q || '';
  return exports.getProducts(req, res);
};

exports.getById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, data: product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const product = await Product.create({ ...req.body, brand: req.body.brand || 'Faruk Fashion' });
    res.status(201).json({ success: true, message: 'Product created', data: product });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.update = async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Product updated', data: product });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.updateStock = async (req, res) => {
  try {
    const quantity = parseInt(req.query.quantity ?? req.body.quantity);
    if (isNaN(quantity) || quantity < 0) {
      return res.status(400).json({ success: false, message: 'Invalid quantity' });
    }
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { stockQuantity: quantity },
      { new: true }
    );
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Stock updated', data: product });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.deactivate = async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, { active: false }, { new: true });
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, message: 'Product deactivated', data: product });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.lowStock = async (req, res) => {
  try {
    const products = await Product.find({
      active: true,
      $expr: { $lte: ['$stockQuantity', '$lowStockThreshold'] },
    });
    res.json({ success: true, data: products });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.categories = async (req, res) => {
  const list = require('../models/Product').CATEGORIES.map((c) => ({
    code: c,
    name: c.replace(/_/g, ' '),
  }));
  res.json({ success: true, data: list });
};
