import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final userId = await AuthService.getUserId();
      if (userId != null && userId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.splashGradientStart, AppColors.splashGradientEnd],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Flash Room Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                'assets/images/flashroom.png',
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            // Tagline at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: const Text(
                'Available near all major temples',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


