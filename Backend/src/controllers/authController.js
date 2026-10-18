const User = require('../models/User');
const LoginLog = require('../models/LoginLog');
const { signToken, createAuthResponse } = require('../utils/jwt');
const { OAuth2Client } = require('google-auth-library');
const crypto = require('crypto');
const { Resend } = require('resend');

const resend = process.env.RESEND_API_KEY
  ? new Resend(process.env.RESEND_API_KEY)
  : null;
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.register = async (req, res) => {
  try {
    const { username, password, fullName, email, phone, address, city, state, pincode, gender, age } = req.body;

    if (await User.findOne({ username })) {
      return res.status(400).json({ success: false, message: 'Username already exists' });
    }
    if (await User.findOne({ email: (email || '').toLowerCase() })) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    if (phone && (await User.findOne({ phone }))) {
      return res.status(400).json({ success: false, message: 'Phone already registered' });
    }

    const user = await User.create({
      username,
      password,
      fullName,
      email: (email || '').toLowerCase(),
      phone,
      address,
      city,
      state,
      pincode,
      gender,
      age,
      roles: ['ROLE_CUSTOMER'],
    });

    const token = signToken(user._id);
    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: createAuthResponse(user, token),
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  let success = false;
  let failureReason = null;
  let user = null;

  try {
    const loginId = (username || '').trim();
    if (!loginId || !password) {
      throw new Error('Username and password are required');
    }

    const escaped = loginId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    user = await User.findOne({
      $or: [
        { username: new RegExp(`^${escaped}$`, 'i') },
        { email: loginId.toLowerCase() },
        { phone: loginId },
      ],
    }).select('+password');

    if (!user || !(await user.comparePassword(password))) {
      failureReason = 'Invalid username or password';
      throw new Error(failureReason);
    }
    if (!user.active) {
      failureReason = 'Account deactivated';
      throw new Error(failureReason);
    }

    user.lastLoginAt = new Date();
    await user.save({ validateBeforeSave: false });

    const token = signToken(user._id);
    success = true;

    res.json({
      success: true,
      message: 'Login successful',
      data: createAuthResponse(user, token),
    });
  } catch (err) {
    res.status(401).json({ success: false, message: err.message || 'Invalid username or password' });
  } finally {
    await LoginLog.create({
      userId: user?._id,
      username: username || '',
      ipAddress: req.headers['x-forwarded-for']?.split(',')[0] || req.ip,
      userAgent: req.headers['user-agent'],
      success,
      failureReason,
    }).catch(() => {});
  }
};

/** Google Sign-In: body = { idToken } or { accessToken, email?, fullName? } */
exports.googleLogin = async (req, res) => {
  try {
    const { idToken, accessToken, email: bodyEmail, fullName: bodyName } = req.body;

    if (!idToken && !accessToken) {
      return res.status(400).json({
        success: false,
        message: 'idToken or accessToken required',
      });
    }
    if (!process.env.GOOGLE_CLIENT_ID) {
      return res.status(500).json({
        success: false,
        message: 'GOOGLE_CLIENT_ID not configured',
      });
    }

    let email = '';
    let googleId = '';
    let fullName = bodyName || 'User';
    let emailVerified = false;

    if (idToken) {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      const payload = ticket.getPayload();
      email = (payload.email || bodyEmail || '').toLowerCase();
      googleId = payload.sub;
      fullName = payload.name || bodyName || (email ? email.split('@')[0] : 'User');
      emailVerified = payload.email_verified === true;
    } else {
      const r = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (!r.ok) {
        return res.status(401).json({
          success: false,
          message: 'Invalid Google access token',
        });
      }
      const profile = await r.json();
      email = (profile.email || bodyEmail || '').toLowerCase();
      googleId = profile.sub;
      fullName =
        profile.name || bodyName || (email ? email.split('@')[0] : 'User');
      emailVerified = profile.email_verified === true;
    }

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Google account has no email',
      });
    }

    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (!user) {
      const base =
        email.split('@')[0].replace(/[^a-zA-Z0-9]/g, '').toLowerCase() ||
        'user';
      let username = base;
      let n = 1;
      while (await User.findOne({ username })) {
        username = `${base}${n++}`;
      }
      user = await User.create({
        username,
        fullName,
        email,
        googleId,
        roles: ['ROLE_CUSTOMER'],
        emailVerified,
      });
    } else {
      if (!user.googleId) {
        user.googleId = googleId;
        await user.save({ validateBeforeSave: false });
      }
      if (!user.active) {
        return res.status(403).json({
          success: false,
          message: 'Account deactivated',
        });
      }
      user.lastLoginAt = new Date();
      await user.save({ validateBeforeSave: false });
    }

    const token = signToken(user._id);
    res.json({
      success: true,
      message: 'Google login successful',
      data: createAuthResponse(user, token),
    });
  } catch (err) {
    res.status(401).json({
      success: false,
      message: err.message || 'Google login failed',
    });
  }
};

function hashValue(v) {
  return crypto.createHash('sha256').update(String(v)).digest('hex');
}

exports.forgotPassword = async (req, res) => {
  try {
    const loginId = (req.body.email || req.body.username || '').trim();
    if (!loginId) {
      return res.status(400).json({
        success: false,
        message: 'Email is required',
      });
    }

    const escaped = loginId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const user = await User.findOne({
      $or: [
        { email: loginId.toLowerCase() },
        { username: new RegExp(`^${escaped}$`, 'i') },
        { phone: loginId },
      ],
    });

    const okMsg = 'If an account exists, an OTP has been sent to the registered email';

    if (!user || !user.email) {
      return res.json({
        success: true,
        message: okMsg,
        data: { emailHint: null },
      });
    }

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    user.resetPasswordOtp = hashValue(otp);
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 min
    await user.save({ validateBeforeSave: false });

    if (resend) {
      await resend.emails.send({
        from: process.env.MAIL_FROM || 'Faruk Fashion <onboarding@resend.dev>',
        to: user.email,
        subject: 'Faruk Fashion – Password reset OTP',
        html: `
          <p>Hi ${user.fullName || user.username},</p>
          <p>Your OTP is:</p>
          <h2 style="letter-spacing:6px;font-size:28px">${otp}</h2>
          <p>Valid for 10 minutes. If you did not request this, ignore this email.</p>
        `,
      });
    } else {
      console.log('[DEV OTP]', user.email, otp);
    }

    res.json({
      success: true,
      message: okMsg,
      data: { emailHint: user.email },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message || 'Could not send OTP',
    });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const otp = (req.body.otp || '').trim();
    if (!email || !otp || otp.length !== 6) {
      return res.status(400).json({
        success: false,
        message: 'Email and 6-digit OTP required',
      });
    }

    const user = await User.findOne({ email });
    if (
      !user ||
      !user.resetPasswordOtp ||
      !user.resetPasswordExpires ||
      user.resetPasswordExpires < new Date()
    ) {
      return res.status(400).json({
        success: false,
        message: 'OTP expired or invalid',
      });
    }

    if (user.resetPasswordOtp !== hashValue(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP',
      });
    }

    const rawToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = hashValue(rawToken);
    user.resetPasswordOtp = undefined;
    user.resetPasswordExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save({ validateBeforeSave: false });

    res.json({
      success: true,
      message: 'OTP verified',
      data: { resetToken: rawToken, email: user.email },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message || 'Verify failed',
    });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const token = (req.body.token || req.body.resetToken || '').trim();
    const password = req.body.password || req.body.newPassword || '';
    if (!token || String(password).length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Valid token and password (min 6 chars) required',
      });
    }

    const hashed = hashValue(token);
    const user = await User.findOne({
      resetPasswordToken: hashed,
      resetPasswordExpires: { $gt: new Date() },
    }).select('+password');

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired session. Request a new OTP.',
      });
    }

    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordOtp = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({
      success: true,
      message: 'Password updated. You can sign in now.',
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message || 'Reset failed',
    });
  }
};