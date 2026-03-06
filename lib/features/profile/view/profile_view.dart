import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/login_view.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../admin/view/admin_login_view.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final ProviderSubscription _authSubscription;
  bool _initialized = false;
  int _adminTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });

    _authSubscription = ref.listenManual(authViewModelProvider, (_, __) {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _authSubscription.close();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);

    // Sync controllers with profile data once when profile is loaded
    profileState.whenData((profile) {
      if (profile != null && !_initialized) {
        _nameController.text = profile.fullName ?? '';
        _addressController.text = profile.address ?? '';
        _phoneController.text = profile.phone ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please sign in to view your profile.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      );
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(profileViewModelProvider.notifier)
                                    .updateProfile(
                                      fullName: _nameController.text.trim(),
                                      address: _addressController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                    );

                                // Reset initialized flag to allow new data to be loaded
                                setState(() {
                                  _initialized = false;
                                });

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await ref
                          .read(profileViewModelProvider.notifier)
                          .logout();

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (route) => false,
                      );
                    },
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleAdminAccess() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds have passed
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _adminTapCount = 0;
    }

    _lastTapTime = now;
    _adminTapCount++;

    if (_adminTapCount == 7) {
      _adminTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginView()),
      );
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _handleAdminAccess,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('Version 0.1.0'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: const Text(
                      'For any queries or support, please contact:\n\n'
                      'Email: support@vaari.com\n'
                      'Phone: +91 1234567890',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'VAARI respects your privacy and is committed to '
                        'protecting your personal information.\n\n'
                        'We collect and use your information only for '
                        'providing and improving our services.\n\n'
                        'Your data is securely stored and never shared '
                        'with third parties without your consent.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await ref.read(profileViewModelProvider.notifier).logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
