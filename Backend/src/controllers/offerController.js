const Offer = require('../models/Offer');

exports.homeBanners = async (req, res) => {
  try {
    const offers = await Offer.find({ active: true, showOnHomeBanner: true }).sort({ priority: 1 });
    res.json({ success: true, data: offers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.activeOffers = async (req, res) => {
  try {
    const now = new Date();
    const offers = await Offer.find({
      active: true,
      startDate: { $lte: now },
      endDate: { $gte: now },
    }).sort({ priority: 1 });
    res.json({ success: true, data: offers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getAll = async (req, res) => {
  try {
    const offers = await Offer.find().sort({ priority: 1 });
    res.json({ success: true, data: offers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const offer = await Offer.create(req.body);
    res.status(201).json({ success: true, message: 'Offer created', data: offer });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.update = async (req, res) => {
  try {
    const offer = await Offer.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!offer) return res.status(404).json({ success: false, message: 'Offer not found' });
    res.json({ success: true, message: 'Offer updated', data: offer });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.toggle = async (req, res) => {
  try {
    const offer = await Offer.findById(req.params.id);
    if (!offer) return res.status(404).json({ success: false, message: 'Offer not found' });
    offer.active = !offer.active;
    await offer.save();
    res.json({ success: true, data: offer });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.remove = async (req, res) => {
  try {
    await Offer.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Offer deleted', data: null });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};
