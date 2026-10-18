require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

const MONGO = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/faruk_fashion';

async function run() {
  const loginId = (process.argv[2] || '').trim();
  const newPassword = (process.argv[3] || '').trim();

  if (!loginId || !newPassword) {
    console.log('Usage: node src/utils/reset-user.js <username|email|phone> <newPassword>');
    process.exit(1);
  }
  if (newPassword.length < 6) {
    console.error('Password must be at least 6 characters');
    process.exit(1);
  }

  await mongoose.connect(MONGO);
  const escaped = loginId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const user = await User.findOne({
    $or: [
      { email: loginId.toLowerCase() },
      { username: new RegExp(`^${escaped}$`, 'i') },
      { phone: loginId },
    ],
  }).select('+password');

  if (!user) {
    console.error('User not found for:', loginId);
    await mongoose.disconnect();
    process.exit(1);
  }

  console.log('Found:', user.username, user.email, user.phone);
  user.password = newPassword;
  user.active = true;
  await user.save();

  const check = await User.findById(user._id).select('+password');
  console.log('Password verify:', (await check.comparePassword(newPassword)) ? 'OK' : 'FAIL');
  console.log('Sign in with:', user.username, '| password:', newPassword);
  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});