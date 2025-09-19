import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Callbacks
  Function(PaymentSuccessResponse)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentError;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Error: ${response.code} - ${response.message}");
    if (onPaymentError != null) {
      onPaymentError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  Future<void> startPayment({
    required double amount,
    required String orderId,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) async {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay test key
      'amount': (amount * 100).toInt(), // Amount in paisa
      'name': 'FriendFund',
      'order_id': orderId,
      'description': description,
      'timeout': 300, // 5 minutes
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'theme': {
        'color': '#2196F3', // Your app's primary color
      },
      'modal': {
        'ondismiss': () {
          debugPrint('Payment modal dismissed');
        },
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error starting payment: $e');
      Get.snackbar(
        'Payment Error',
        'Failed to start payment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

// Payment order model
class PaymentOrder {
  final String id;
  final String entity;
  final int amount;
  final int amountPaid;
  final int amountDue;
  final String currency;
  final String receipt;
  final String status;
  final int attempts;
  final Map<String, dynamic>? notes;
  final int createdAt;

  PaymentOrder({
    required this.id,
    required this.entity,
    required this.amount,
    required this.amountPaid,
    required this.amountDue,
    required this.currency,
    required this.receipt,
    required this.status,
    required this.attempts,
    this.notes,
    required this.createdAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'],
      entity: json['entity'],
      amount: json['amount'],
      amountPaid: json['amount_paid'],
      amountDue: json['amount_due'],
      currency: json['currency'],
      receipt: json['receipt'],
      status: json['status'],
      attempts: json['attempts'],
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity': entity,
      'amount': amount,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'currency': currency,
      'receipt': receipt,
      'status': status,
      'attempts': attempts,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
