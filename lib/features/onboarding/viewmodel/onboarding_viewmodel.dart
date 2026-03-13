import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/onboarding_model.dart';

final onboardingViewModelProvider = NotifierProvider<OnboardingViewModel, int>(
  OnboardingViewModel.new,
);

class OnboardingViewModel extends Notifier<int> {
  @override
  int build() => 0;

  final List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Furniture & Electronics',
      description:
          'Shop quality furniture and modern electronics in one place.',
      imageAsset: 'assets/images/onboarding/one.png',
    ),
    OnboardingModel(
      title: 'Smart & Secure',
      description:
          'Fast checkout, secure payments, and real-time order updates.',
      imageAsset: 'assets/images/onboarding/two.png',
    ),
    OnboardingModel(
      title: 'Minimal Experience',
      description: 'Clean design focused on comfort and usability.',
      imageAsset: 'assets/images/onboarding/three.png',
    ),
  ];

  void nextPage() {
    if (state < pages.length - 1) {
      state++;
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }
}
