import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  void init({
    required Function onSuccess,
    required Function onError,
    required Function onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required String key,
    required int amount,
    required String name,
    required String description,
    required String email,
  }) {
    final options = {
      'key': key,
      'amount': amount, // in paise
      'name': name,
      'description': description,
      'prefill': {'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
