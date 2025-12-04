import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(localizations),
                  const SizedBox(height: 40),
                  _buildEmailField(localizations),
                  const SizedBox(height: 30),
                  _buildSendResetLinkButton(localizations),
                  const SizedBox(height: 20),
                  _buildBackToLogin(localizations),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/loginbg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations?.forgotPassword ?? 'Forgot Password?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.red,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          localizations?.resetPasswordDescription ?? 'Enter your email address and we will send you a reset link',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.red.withOpacity(0.9),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations? localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: localizations?.enterYourEmail ?? 'Enter your email',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildSendResetLinkButton(AppLocalizations? localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendResetLink,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                localizations?.sendResetLink ?? 'Send Reset Link',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _handleSendResetLink() async {
    final localizations = AppLocalizations.of(context);
    
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar(localizations?.pleaseEnterYourEmail ?? 'Please enter your email');
      return;
    }
    if (!_emailController.text.trim().contains('@')) {
      _showSnackBar(localizations?.pleaseEnterValidEmail ?? 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Add API call here when endpoint is available
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _showSuccessDialog(localizations);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(AppLocalizations? localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                localizations?.resetLinkSent ?? 'Reset Link Sent',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            localizations?.resetLinkSentMessage ?? 'We have sent a password reset link to your email address. Please check your inbox.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Text(
                localizations?.ok ?? 'OK',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBackToLogin(AppLocalizations? localizations) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: Text(
          localizations?.backToLogin ?? 'Back to Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
