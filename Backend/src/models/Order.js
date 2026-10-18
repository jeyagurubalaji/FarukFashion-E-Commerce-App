const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    productName: String,
    imageUrl: String,
    color: String,
    size: String,
    quantity: { type: Number, required: true, min: 1 },
    unitPrice: Number,
    totalPrice: Number,
  },
  { _id: false }
);

const addressSchema = new mongoose.Schema(
  {
    line1: String,
    line2: String,
    city: String,
    state: String,
    pincode: String,
    landmark: String,
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    orderNumber: { type: String, unique: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    customerName: String,
    customerPhone: String,
    customerEmail: String,
    shippingAddress: addressSchema,
    items: [orderItemSchema],
    subTotal: Number,
    discountAmount: { type: Number, default: 0 },
    shippingCharge: { type: Number, default: 0 },
    taxAmount: { type: Number, default: 0 },
    totalAmount: Number,
    paymentStatus: {
      type: String,
      enum: ['PENDING', 'PAID', 'FAILED', 'REFUNDED', 'PARTIALLY_REFUNDED'],
      default: 'PENDING',
    },
    paymentId: String,
    paymentMethod: { type: String, default: 'COD' },
    status: {
      type: String,
      enum: [
        'PLACED',
        'CONFIRMED',
        'PACKED',
        'SHIPPED',
        'OUT_FOR_DELIVERY',
        'DELIVERED',
        'CANCELLED',
        'RETURN_REQUESTED',
        'RETURNED',
        'REFUNDED',
      ],
      default: 'PLACED',
    },
    trackingNumber: String,
    courierName: String,
    notes: String,
    deliveredAt: Date,
    cancelledAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);
