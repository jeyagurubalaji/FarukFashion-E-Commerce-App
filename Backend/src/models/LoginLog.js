const mongoose = require('mongoose');

const loginLogSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    username: String,
    ipAddress: String,
    userAgent: String,
    deviceInfo: String,
    success: Boolean,
    failureReason: String,
  },
  { timestamps: { createdAt: 'loginAt', updatedAt: false } }
);

module.exports = mongoose.model('LoginLog', loginLogSchema);
