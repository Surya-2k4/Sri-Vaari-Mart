import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/view/home_view.dart';
import '../cart/view/cart_view.dart';
import '../orders/view/order_history_view.dart';
import '../profile/view/profile_view.dart';
import '../cart/viewmodel/cart_badge_provider.dart';

import 'package:vaari/features/navigation/navigation_provider.dart';

class MainNavigationView extends ConsumerWidget {
  const MainNavigationView({super.key});

  final List<Widget> _screens = const [
    HomeView(),
    CartView(),
    OrderHistoryView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

          /// 🛒 CART WITH BADGE
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, _) {
                final count = ref.watch(cartItemCountProvider);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (count > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Cart',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
