const jwt = require('jsonwebtoken');

exports.signToken = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET || 'FarukFashionSecretKeyChangeThisInProduction2026',
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );
};

exports.createAuthResponse = (user, token) => ({
  accessToken: token,
  tokenType: 'Bearer',
  userId: user._id,
  username: user.username,
  fullName: user.fullName,
  email: user.email,
  roles: user.roles,
});
