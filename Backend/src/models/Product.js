const mongoose = require('mongoose');

const CATEGORIES = [
  'HANDBAGS',
  'TROLLEY_BAGS',
  'SCHOOL_BAGS',
  'COLLEGE_BAGS',
  'OFFICE_BAGS',
  'SLING_BAGS',
  'KIDS_BAGS',
  'TRAVEL_KITS',
  'TRAVELLING_BAGS',
  'LAPTOP_BAGS',
  'OTHER',
];

const productSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, index: true },
    description: String,
    category: { type: String, enum: CATEGORIES, required: true, index: true },
    subCategory: String,
    price: { type: Number, required: true, min: 0 },
    discountPrice: Number,
    discountPercent: Number,
    brand: { type: String, default: 'Faruk Fashion' },
    colors: [String],
    sizes: [String],
    material: String,
    weightKg: Number,
    imageUrls: [String],
    tags: [String],
    stockQuantity: { type: Number, required: true, min: 0, default: 0 },
    lowStockThreshold: { type: Number, default: 5 },
    active: { type: Boolean, default: true },
    featured: { type: Boolean, default: false },
    averageRating: { type: Number, default: 0 },
    reviewCount: { type: Number, default: 0 },
    targetAudience: { type: String, default: 'Unisex' },
    gstPercent: { type: Number, default: 18, min: 0, max: 28 },
  },
  { timestamps: true }
);

productSchema.index({ name: 'text', tags: 'text' });

module.exports = mongoose.model('Product', productSchema);
module.exports.CATEGORIES = CATEGORIES;