import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/features/auth/view/login_view.dart';
import 'package:vaari/features/auth/view/signup_view.dart';
import 'package:vaari/core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';

class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Responsive(
              mobile: _buildMobileLayout(context),
              desktop: _buildDesktopLayout(context, theme, size),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const Spacer(),
                _buildIllustration(250),
                const Spacer(),
                _buildButtons(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme, Size size) {
    return Row(
      children: [
        // Left side: Illustration
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primaryBlack.withValues(alpha: 0.02),
            child: Center(child: _buildIllustration(400)),
          ),
        ),
        // Right side: Content
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome =)',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hi there!\nWe\'re here to help you get your daily essentials.\nThe choice is yours: Log in or create an account.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 60),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildButtons(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Welcome =)',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hi there!\nWe\'re here to help you get your daily essentials.\nThe choice is yours: Log in or create an account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildIllustration(double height) {
    return Image.asset(
      'assets/images/auth_welcome_illustration.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: height * 0.6,
        color: Colors.black12,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupView()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create Account'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black12),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log In'),
          ),
        ),
      ],
    );
  }
}
