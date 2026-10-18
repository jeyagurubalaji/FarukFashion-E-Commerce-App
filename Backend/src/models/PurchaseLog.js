const mongoose = require('mongoose');

const purchaseLogSchema = new mongoose.Schema(
  {
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    orderNumber: String,
    totalAmount: Number,
    paymentMethod: String,
    paymentStatus: String,
    itemCount: Number,
  },
  { timestamps: { createdAt: 'purchasedAt', updatedAt: false } }
);

module.exports = mongoose.model('PurchaseLog', purchaseLogSchema);
