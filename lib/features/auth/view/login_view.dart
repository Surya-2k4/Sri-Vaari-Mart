import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/features/navigation/main_navigation_view.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'signup_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationView()),
              (route) => false,
            );
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        },
      );
    });

    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sign In', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),

            authState.isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(authViewModelProvider.notifier)
                            .signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                      },
                      child: const Text('Login'),
                    ),
                  ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupView()),
                );
              },
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
