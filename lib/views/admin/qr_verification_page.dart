import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRVerificationPage extends StatefulWidget {
  const QRVerificationPage({Key? key}) : super(key: key);

  @override
  State<QRVerificationPage> createState() => _QRVerificationPageState();
}

class _QRVerificationPageState extends State<QRVerificationPage> {
  bool _scanning = true;
  bool _torchOn = false;
  String? _resultMessage;
  Color _resultColor = Colors.transparent;
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  Future<void> _verifyBooking(String qrData) async {
    if (!_scanning) return;

    setState(() {
      _scanning = false;
      _resultMessage = "Checking booking...";
      _resultColor = Colors.orange;
    });

    try {
      final parts = qrData.split(';');
      if (parts.length < 3) throw Exception("Invalid QR format");

      final bookingId = parts[0].split(':')[1];
      final eventId = parts[1].split(':')[1];
      final userId = parts[2].split(':')[1];

      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists) {
        setState(() {
          _resultMessage =
          "✅ Booking Verified!\nEvent: $eventId\nUser: $userId";
          _resultColor = Colors.green;
        });
      } else {
        setState(() {
          _resultMessage = "❌ Invalid Booking!";
          _resultColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = "⚠️ Error verifying booking!";
        _resultColor = Colors.red;
      });
    }

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _scanning = true;
      _resultMessage = null;
    });
  }

  void _toggleTorch() {
    setState(() {
      _torchOn = !_torchOn;
      _scannerController.toggleTorch();
    });
  }

  void _restartScanner() {
    setState(() {
      _scanning = true;
      _resultMessage = null;
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Booking Verification"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full screen QR Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              final String? data = barcode.rawValue;
              if (data != null && _scanning) _verifyBooking(data);
            },
          ),
          // Result overlay
          if (!_scanning && _resultMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _resultColor,
                  ),
                ),
              ),
            ),
          // Floating Restart Scanner button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _restartScanner,
              label: const Text("Restart Scanner"),
              icon: const Icon(Icons.refresh),
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}