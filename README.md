# 🛍️ Faruk Fashion - E-Commerce App

**Style That Speaks** — A full-stack, cross-platform e-commerce application for fashion bags, trolleys, handbags, school bags, and travelling kits.

## ✨ Features

- User registration, login and profile management
- Google Sign-In with OAuth2
- Forgot password with email OTP
- Product catalogue with categories and search
- Product details with high-resolution images
- Shopping cart and wishlist
- Razorpay online payments
- Cash on Delivery
- Order tracking and order history
- Multiple delivery addresses
- Admin dashboard
- Product, stock, order and user management
- Dark / Light theme
- Android and Web support

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3, Dart, Provider |
| Backend | Node.js, Express.js |
| Authentication | JWT, Firebase Auth, Google OAuth2 |
| Database | MongoDB Atlas |
| Payments | Razorpay |
| Email / SMS | Resend, Twilio / MSG91 |
| Deployment | Vercel, Render |

## 📁 Project Structure

```text
FarukFashion/
│
├── Frontend/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── utils/
│   │   └── main.dart
│   ├── android/
│   └── pubspec.yaml
│
└── Backend/
    ├── controllers/
    ├── models/
    ├── routes/
    ├── utils/
    └── index.js
```

## 🚀 Setup

### Backend

```bash
cd Backend
npm install
npm start
```

### Frontend

```bash
cd Frontend
flutter pub get
flutter run
```

### Build Android APK

```bash
flutter build apk --release
```

## 🔐 Environment Configuration

Configure the backend URL and Google Client ID in:

```text
Frontend/lib/utils/constants.dart
```

Example:

```dart
static const String baseUrl =
    'https://farukfashion-express.vercel.app/api';

static const String googleClientId =
    'YOUR_GOOGLE_CLIENT_ID';
```

For the backend, keep sensitive credentials in environment variables:

```env
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

**Never commit `.env` files or private API credentials to GitHub.**

## 🔗 Main API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Register user |
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/google` | Google Sign-In |
| GET | `/api/products` | Get products |
| POST | `/api/orders` | Create order |
| POST | `/api/orders/verify-payment` | Verify payment |
| GET | `/api/orders/my` | Get customer orders |
| `*` | `/api/admin/**` | Admin operations |

## 🔒 Security

- JWT-based authentication
- Google OAuth2 verification
- Role-based admin access control
- Protected API routes
- Razorpay payment verification
- Secure environment-based configuration

## 🌐 Platforms

- **Android** ✅
- **Web** ✅

## 📄 License

Private project developed for **Faruk Fashion**.

**All rights reserved.**