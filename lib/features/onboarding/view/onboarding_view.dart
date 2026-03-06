import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/onboarding_viewmodel.dart';

class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    final page = viewModel.pages[index];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (index == viewModel.pages.length - 1) {
                    await viewModel.completeOnboarding();
                    // next module → Auth (later)
                  } else {
                    viewModel.nextPage();
                  }
                },
                child: Text(
                  index == viewModel.pages.length - 1 ? 'Get Started' : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
