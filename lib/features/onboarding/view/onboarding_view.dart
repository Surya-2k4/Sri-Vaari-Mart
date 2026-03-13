import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/onboarding_viewmodel.dart';
import '../../navigation/main_navigation_view.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:convert';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(onboardingViewModelProvider.notifier);
    final pages = viewModel.pages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return _buildPage(page);
            },
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage < pages.length - 1)
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationView(),
                              ),
                            );
                          },
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60),
                      GestureDetector(
                        onTap: () {
                          if (_currentPage < pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationView(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlack,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlack.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage == pages.length - 1 ? 'FINISH' : 'NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: _buildImage(page.imageAsset),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageAsset) {
    if (imageAsset.startsWith('data:image')) {
      // Handle base64
      try {
        final base64String = imageAsset.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const Icon(Icons.image_outlined, size: 100, color: Colors.grey);
      }
    } else if (imageAsset.startsWith('http')) {
      return Image.network(
        imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 100, color: Colors.grey),
      );
    } else {
      return Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 100, color: Colors.grey),
      );
    }
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primaryBlack : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
