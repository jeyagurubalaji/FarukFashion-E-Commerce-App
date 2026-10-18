const mongoose = require('mongoose');

const offerSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    description: String,
    bannerImageUrl: String,
    type: { type: String, enum: ['PERCENTAGE', 'FLAT', 'BUY_X_GET_Y'], default: 'PERCENTAGE' },
    discountValue: Number,
    minOrderAmount: Number,
    applicableCategories: [String],
    applicableProductIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],
    startDate: Date,
    endDate: Date,
    active: { type: Boolean, default: true },
    showOnHomeBanner: { type: Boolean, default: true },
    priority: { type: Number, default: 10 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Offer', offerSchema);
