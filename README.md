# Faruk Fashion - E-Commerce App

**Style That Speaks** — A full-stack e-commerce mobile and web application for fashion bags, trolleys, handbags, and travelling kits.

## Features

- Customer registration, login & profile management
- Google Sign-In with OAuth2
- Forgot password with email OTP
- Product catalogue with categories, search & high-resolution imagery
- Shopping cart, wishlist and checkout
- Razorpay online payments + Cash on Delivery
- Order tracking and multi-address management
- Admin dashboard for products, stock, orders, and users
- Dark / light elegant themes
- Cross-platform support for Android and Web

## Tech Stack

| Layer          | Technology                     |
| -------------- | ------------------------------ |
| Frontend       | Flutter 3, Dart, Provider      |
| Backend        | Node.js, Express.js            |
| Authentication | JWT, Firebase Auth, Google OAuth2 |
| Database       | MongoDB Atlas                  |
| Payments       | Razorpay                       |
| Email / SMS    | Resend, Twilio /               |
| Deployment     | Vercel,                        |

## Project Structure

```text
FarukFashion/
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
Setup & Quick Start
Backend
Bash
cd Backend
npm install
npm start
Frontend (Flutter)
Bash
cd Frontend
flutter pub get
flutter run
To build a release APK for Android:

Bash
flutter build apk --release
Environment Configuration
Configure your backend URL and Google Client ID in Frontend/lib/utils/constants.dart:

Dart
static const String baseUrl = '[https://farukfashion-express.vercel.app/api](https://farukfashion-express.vercel.app/api)';
static const String googleClientId = '788219758793-92vdb8hopvdq38laal2agsoj9gudp0fm.apps.googleusercontent.com';
Main API Endpoints
Method	Endpoint	Purpose
POST	/api/auth/register	Register user
POST	/api/auth/login	User login
POST	/api/auth/google	Google Sign-In
GET	/api/products	Get products
POST	/api/orders	Create order
POST	/api/orders/verify-payment	Verify payment
GET	/api/orders/my	Customer orders
*	/api/admin/**	Admin operations
Security
JWT-based authentication with secure local storage

Google OAuth2 verification via google-auth-library

Role-based admin access control

Multidex support enabled for Android release builds

License
Private project for Faruk Fashion. All rights reserved.