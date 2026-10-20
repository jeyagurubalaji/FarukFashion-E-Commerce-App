import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/address_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'screens/home/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'widgets/brand_logo.dart';
import 'screens/auth/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mandatory: Initialize Firebase before running the app to prevent startup crashes
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FarukFashionApp());
}

class FarukFashionApp extends StatelessWidget {
  const FarukFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()..load()),
        ChangeNotifierProvider(create: (_) => AddressProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Faruk Fashion',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightElegant,
            darkTheme: AppTheme.darkElegant,
            themeMode: theme.mode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    await context.read<AuthProvider>().tryAutoLogin();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final frag = Uri.base.fragment;
    if (frag.contains('reset-password')) {
      final q = frag.contains('?')
          ? Uri.splitQueryString(frag.split('?').last)
          : <String, String>{};
      final token = q['token'];
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    final Widget next;
    if (auth.isLoggedIn) {
      next = auth.user?.isAdmin == true
          ? const AdminShell()
          : const MainShell();
    } else {
      next = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(size: 120, borderWidth: 3),
              const SizedBox(height: 28),
              Text(
                'FARUK FASHION',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      letterSpacing: 3,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Style That Speaks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightGold,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}