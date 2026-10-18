const express = require('express');
const path = require('path');
const router = express.Router();

const auth = require('../middleware/auth');
const authCtrl = require('../controllers/authController');
const productCtrl = require('../controllers/productController');
const orderCtrl = require('../controllers/orderController');
const paymentCtrl = require('../controllers/paymentController');
const returnCtrl = require('../controllers/returnController');
const offerCtrl = require('../controllers/offerController');
const recCtrl = require('../controllers/recommendationController');
const adminCtrl = require('../controllers/adminController');
const uploadCtrl = require('../controllers/uploadController');
const upload = require('../middleware/upload');

// Public
router.get('/public/health', (req, res) => {
  res.json({ success: true, message: 'Faruk Fashion Backend is running', data: 'OK' });
});
router.get('/categories', productCtrl.categories);

router.post('/auth/register', authCtrl.register);
router.post('/auth/login', authCtrl.login);
router.post('/auth/google', authCtrl.googleLogin);
router.post('/auth/forgot-password', authCtrl.forgotPassword);
router.post('/auth/verify-otp', authCtrl.verifyOtp);
router.post('/auth/reset-password', authCtrl.resetPassword);

router.get('/products', productCtrl.getProducts);
router.get('/products/category/:category', productCtrl.getByCategory);
router.get('/products/featured', productCtrl.getFeatured);
router.get('/products/search', productCtrl.search);
router.get('/products/:id', productCtrl.getById);

router.get('/offers/banners', offerCtrl.homeBanners);
router.get('/offers/active', offerCtrl.activeOffers);

// Authenticated
router.post('/orders', auth.protect, orderCtrl.placeOrder);
router.get('/orders/my', auth.protect, orderCtrl.myOrders);
router.get('/orders/number/:orderNumber', auth.protect, orderCtrl.getByNumber);
router.get('/orders/:id', auth.protect, orderCtrl.getById);

router.post('/payments/create/:orderId', auth.protect, paymentCtrl.createPayment);
router.post('/payments/verify', auth.protect, paymentCtrl.verifyPayment);
router.post('/payments/cod/confirm/:orderId', auth.protect, paymentCtrl.confirmCod);

router.post('/returns', auth.protect, returnCtrl.requestReturn);
router.get('/returns/my', auth.protect, returnCtrl.myReturns);

router.get('/recommendations', auth.optionalAuth, recCtrl.getRecommendations);

// Admin products
router.post('/admin/products', auth.protect, auth.restrictTo('ROLE_ADMIN'), productCtrl.create);
router.put('/admin/products/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), productCtrl.update);
router.patch('/admin/products/:id/stock', auth.protect, auth.restrictTo('ROLE_ADMIN'), productCtrl.updateStock);
router.delete('/admin/products/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), productCtrl.deactivate);
router.get('/admin/products/low-stock', auth.protect, auth.restrictTo('ROLE_ADMIN'), productCtrl.lowStock);

router.get('/admin/orders', auth.protect, auth.restrictTo('ROLE_ADMIN'), orderCtrl.allOrders);
router.patch('/admin/orders/:id/status', auth.protect, auth.restrictTo('ROLE_ADMIN'), orderCtrl.updateStatus);
router.delete('/admin/orders/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), orderCtrl.remove);

router.get('/returns/admin/all', auth.protect, auth.restrictTo('ROLE_ADMIN'), returnCtrl.allReturns);
router.patch('/returns/admin/:id/status', auth.protect, auth.restrictTo('ROLE_ADMIN'), returnCtrl.updateStatus);

router.get('/offers/admin/all', auth.protect, auth.restrictTo('ROLE_ADMIN'), offerCtrl.getAll);
router.post('/offers/admin', auth.protect, auth.restrictTo('ROLE_ADMIN'), offerCtrl.create);
router.put('/offers/admin/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), offerCtrl.update);
router.patch('/offers/admin/:id/toggle', auth.protect, auth.restrictTo('ROLE_ADMIN'), offerCtrl.toggle);
router.delete('/offers/admin/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), offerCtrl.remove);

// Admin dashboard & customers
router.get('/admin/dashboard', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.dashboard);
router.get('/admin/customers', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.listCustomers);
router.put('/admin/customers/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.updateCustomer);
router.patch('/admin/customers/:id/toggle', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.toggleCustomer);
router.delete('/admin/customers/:id', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.deleteCustomer);
router.get('/admin/returns', auth.protect, auth.restrictTo('ROLE_ADMIN'), adminCtrl.returnsList);

// Image upload (admin)
router.post(
  '/admin/upload',
  auth.protect,
  auth.restrictTo('ROLE_ADMIN'),
  upload.array('images', 5),
  uploadCtrl.uploadImages
);

// Serve uploaded files
router.use('/uploads', express.static(path.join(__dirname, '../../uploads')));

module.exports = router;