import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:vaari/features/profile/viewmodel/profile_viewmodel.dart';

import 'package:vaari/features/navigation/navigation_provider.dart';
import '../../cart/viewmodel/cart_viewmodel.dart';
import '../viewmodel/checkout_viewmodel.dart';
import '../viewmodel/order_history_viewmodel.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  late Razorpay _razorpay;
  String _selectedPaymentMethod = 'Razorpay';
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final cartItems = ref.read(cartViewModelProvider).value ?? [];

      await ref
          .read(checkoutViewModelProvider.notifier)
          .placeOrder(
            items: cartItems,
            paymentMethod: 'Razorpay',
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;

      // Reload cart to reflect cleared items
      await ref.read(cartViewModelProvider.notifier).loadCart();

      // Invalidate orders provider to force refresh
      ref.invalidate(orderHistoryViewModelProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. Order placed!')),
      );

      // Navigate to a state where user can see orders
      Navigator.popUntil(context, (route) => route.isFirst);

      // Switch to Orders tab
      ref.read(navigationIndexProvider.notifier).state = 2;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placement failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }

  void _handleCODPayment() async {
    try {
      final cartItems = ref.read(cartViewModelProvider).value ?? [];

      if (_addressController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide delivery address and phone number'),
          ),
        );
        return;
      }

      await ref
          .read(checkoutViewModelProvider.notifier)
          .placeOrder(
            items: cartItems,
            paymentMethod: 'COD',
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;

      // Reload cart to reflect cleared items
      await ref.read(cartViewModelProvider.notifier).loadCart();

      // Invalidate orders provider to force refresh
      ref.invalidate(orderHistoryViewModelProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully (COD)!')),
      );

      // Navigate to a state where user can see orders
      Navigator.popUntil(context, (route) => route.isFirst);

      // Switch to Orders tab
      ref.read(navigationIndexProvider.notifier).state = 2;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placement failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _startPayment(List items) {
    if (_selectedPaymentMethod == 'COD') {
      _handleCODPayment();
      return;
    }

    if (_addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide delivery address and phone number'),
        ),
      );
      return;
    }

    final totalAmount = items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    final options = {
      'key': 'rzp_test_RxNS07vedRdPJO',
      'amount': (totalAmount * 100).toInt(),
      'name': 'Sri Vaari Mart',
      'description': 'Purchase from Vaari',
      'prefill': {
        'contact': _phoneController.text.trim(),
        'email': ref.read(profileViewModelProvider).value?.email ?? '',
      },
    };

    _razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartViewModelProvider);
    final checkoutState = ref.watch(checkoutViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);

    profileState.whenData((profile) {
      if (profile != null && !_initialized) {
        _addressController.text = profile.address ?? '';
        _phoneController.text = profile.phone ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items to checkout'));
          }

          final total = items.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Address',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.check_circle : Icons.edit),
                      color: _isEditing ? Colors.green : null,
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _phoneController,
                          readOnly: !_isEditing,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            filled: !_isEditing,
                            fillColor: !_isEditing
                                ? Colors.grey.withAlpha(10)
                                : null,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          readOnly: !_isEditing,
                          decoration: InputDecoration(
                            labelText: 'Full Address',
                            prefixIcon: const Icon(Icons.location_on),
                            filled: !_isEditing,
                            fillColor: !_isEditing
                                ? Colors.grey.withAlpha(10)
                                : null,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Order Summary
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${item.quantity}x '),
                          Expanded(child: Text(item.name)),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Payment Method
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Online Payment (Razorpay)'),
                  value: 'Razorpay',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Cash on Delivery (COD)'),
                  value: 'COD',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Project Details
                Card(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withAlpha(50),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Order Information',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order will be processed by Sri Vaari Mart. We ensure fresh quality and timely delivery for all our customers.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                checkoutState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _startPayment(items),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedPaymentMethod == 'COD'
                                ? 'Place Order (COD)'
                                : 'Pay Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
