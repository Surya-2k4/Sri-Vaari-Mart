import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/viewmodel/category_viewmodel.dart';
import 'admin_product_management_view.dart';
import 'admin_order_management_view.dart';
import '../viewmodel/admin_auth_provider.dart';

class AdminPanelView extends ConsumerStatefulWidget {
  const AdminPanelView({super.key});

  @override
  ConsumerState<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends ConsumerState<AdminPanelView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminProductManagementView(),
    AdminOrderManagementView(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmation(context);
              if (shouldExit && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(adminAuthProvider.notifier).logout();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => Consumer(
                      builder: (context, ref, _) {
                        final categories = ref.watch(categoryViewModelProvider);

                        return categories.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => AlertDialog(
                            title: const Text('Error'),
                            content: Text('Failed to load categories: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                          data: (categoryList) {
                            if (categoryList.isEmpty) {
                              return AlertDialog(
                                title: const Text('No Categories'),
                                content: const Text(
                                  'Please add categories to the database first.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            }
                            return ProductFormDialog(categories: categoryList);
                          },
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Admin Panel'),
            content: const Text(
              'Are you sure you want to exit the admin panel?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
