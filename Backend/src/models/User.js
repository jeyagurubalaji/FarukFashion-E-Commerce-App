const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true, minlength: 3 },
    password: { type: String, minlength: 6, select: false },
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    phone: { type: String, unique: true, sparse: true },
    googleId: { type: String, unique: true, sparse: true },
    address: String,
    city: String,
    state: String,
    pincode: String,
    gender: { type: String, enum: ['MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY'] },
    age: Number,
    roles: {
      type: [String],
      enum: ['ROLE_CUSTOMER', 'ROLE_ADMIN', 'ROLE_SUPPORT'],
      default: ['ROLE_CUSTOMER'],
    },
    preferredCategories: [String],
    preferredColors: [String],
    preferredStyle: String,
    active: { type: Boolean, default: true },
    emailVerified: { type: Boolean, default: false },
    lastLoginAt: Date,
    resetPasswordToken: String,
    resetPasswordOtp: String,
    resetPasswordExpires: Date,
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidate) {
  if (!this.password) return false;
  return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('User', userSchema);