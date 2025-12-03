import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class PaymentService extends StatefulWidget {
  final String orderId;
  final double totalAmount;

  /// IMPORTANT: Now returns paymentMethod
  final Future<void> Function(String paymentMethod)? onPaymentSuccess;

  const PaymentService({
    super.key,
    required this.orderId,
    required this.totalAmount,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentService> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentService> {
  bool isProcessing = false;

  String cusName = '';
  String cusEmail = '';
  String cusPhone = '';

  String paymentMethod = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        cusName = user.displayName ?? 'Customer';
        cusEmail = user.email ?? 'customer@example.com';
        cusPhone = '01700000000';
      });
    }
  }

  // 🔵 SSLCommerz / CARD PAYMENT
  Future<void> _handleSSLCommerzPayment() async {
    setState(() {
      isProcessing = true;
      paymentMethod = "Card";
    });

    try {
      final response = await http.post(
        Uri.parse("https://sandbox.sslcommerz.com/gwprocess/v4/api.php"),
        body: {
          "store_id": "YOUR_STORE_ID",
          "store_passwd": "YOUR_STORE_PASS",
          "total_amount": widget.totalAmount.toString(),
          "currency": "BDT",
          "tran_id": widget.orderId,
          "success_url": "https://yourdomain.com/success",
          "fail_url": "https://yourdomain.com/fail",
          "cancel_url": "https://yourdomain.com/cancel",
          "cus_name": cusName,
          "cus_email": cusEmail,
          "cus_phone": cusPhone,
        },
      );

      final data = jsonDecode(response.body);

      if (data["GatewayPageURL"] != null) {
        final url = Uri.parse(data["GatewayPageURL"]);

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          if (widget.onPaymentSuccess != null) {
            await widget.onPaymentSuccess!(paymentMethod);
          }
        }
      }
    } catch (e) {
      debugPrint("SSLCommerz Payment Error: $e");
    }

    setState(() => isProcessing = false);
  }

  // 🔵 MOBILE BANKING PAYMENT
  Future<void> _handleMobileBankingPayment(String provider) async {
    setState(() {
      isProcessing = true;
      paymentMethod = provider;
    });

    try {
      final url = Uri.parse(
        "https://yourdomain.com/$provider/pay?"
            "amount=${widget.totalAmount}&"
            "order=${widget.orderId}",
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (widget.onPaymentSuccess != null) {
          await widget.onPaymentSuccess!(paymentMethod);
        }
      }
    } catch (e) {
      debugPrint("$provider Payment Error: $e");
    }

    setState(() => isProcessing = false);
  }

  void _handleBkashPayment() => _handleMobileBankingPayment("bKash");
  void _handleNagadPayment() => _handleMobileBankingPayment("Nagad");
  void _handleRocketPayment() => _handleMobileBankingPayment("Rocket");

  // 🔵 DEV TEST PAYMENT
  Future<void> _handleTestPayment() async {
    setState(() {
      isProcessing = true;
      paymentMethod = "Test";
    });

    await Future.delayed(const Duration(seconds: 1));

    if (widget.onPaymentSuccess != null) {
      await widget.onPaymentSuccess!(paymentMethod);
    }

    setState(() => isProcessing = false);
  }

  // 🔵 BUTTON BUILDER
  Widget _buildPaymentButton(String text, VoidCallback onPressed,
      {Color color = Colors.blueAccent}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  // 🔵 BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "Total Amount: ৳${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                if (isProcessing)
                  const Center(child: CircularProgressIndicator()),

                if (!isProcessing) ...[
                  _buildPaymentButton(
                      "Pay with SSLCommerz / Card", _handleSSLCommerzPayment),
                  const SizedBox(height: 12),
                  _buildPaymentButton("Pay with bKash", _handleBkashPayment),
                  const SizedBox(height: 12),
                  _buildPaymentButton("Pay with Nagad", _handleNagadPayment),
                  const SizedBox(height: 12),
                  _buildPaymentButton("Pay with Rocket", _handleRocketPayment),
                  const SizedBox(height: 20),
                  _buildPaymentButton("Test Payment (Dev)", _handleTestPayment,
                      color: Colors.orangeAccent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}