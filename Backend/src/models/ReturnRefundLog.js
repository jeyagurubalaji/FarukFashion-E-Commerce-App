const mongoose = require('mongoose');

const returnRefundSchema = new mongoose.Schema(
  {
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    orderNumber: String,
    productIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],
    reason: String,
    description: String,
    status: {
      type: String,
      enum: ['REQUESTED', 'APPROVED', 'REJECTED', 'PICKED_UP', 'RECEIVED', 'REFUNDED', 'CLOSED'],
      default: 'REQUESTED',
    },
    refundAmount: Number,
    refundTransactionId: String,
    refundMethod: String,
    processedAt: Date,
  },
  { timestamps: { createdAt: 'requestedAt', updatedAt: true } }
);

module.exports = mongoose.model('ReturnRefundLog', returnRefundSchema);
