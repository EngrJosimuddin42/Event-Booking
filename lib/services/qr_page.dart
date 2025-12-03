import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:event_booking/models/booking_model.dart';
import 'package:intl/intl.dart';

class QRPage extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();

  QRPage({super.key});

  String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    late final Booking booking;

    if (arg is Booking) {
      booking = arg;
    } else if (arg is Map<String, dynamic> && arg['id'] != null) {
      booking = Booking.fromMap(arg, arg['id']);
    } else {
      throw Exception('Invalid argument passed to QRPage');
    }

    // Event time text
    final eventTimeText = booking.eventEndDateTime != null

        ? "${formatDate(booking.eventDateTime)} - ${formatDate(booking.eventEndDateTime!)}"
        : formatDate(booking.eventDateTime);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Ticket'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Screenshot(
            controller: screenshotController,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data:
                      'BookingID:${booking.id};EventID:${booking.eventId};UserID:${booking.userId};Tickets:${booking.ticketCount}',
                      version: QrVersions.auto,
                      size: 250,
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Event: ${booking.eventTitle ?? "N/A"}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Booking ID: ${booking.id}'),
                        Text('Email: ${booking.userEmail ?? "N/A"}'),
                        Text('User: ${booking.userName ?? "N/A"}'),
                        Text('Payment Method: ${booking.paymentMethod ?? "N/A"}'),
                        Text('Tickets: ${booking.ticketCount}'),
                        Text('Event Time: $eventTimeText'),
                        Text('Booking Time: ${formatDate(booking.bookingTime)}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final image = await screenshotController.capture();
                                if (image == null) return;

                                final directory = await getTemporaryDirectory();
                                final imagePath =
                                await File('${directory.path}/ticket.png')
                                    .create();
                                await imagePath.writeAsBytes(image);

                                await Share.shareXFiles([XFile(imagePath.path)],
                                    text: 'My Event Ticket');
                              } catch (e) {
                                Get.snackbar('Error',
                                    'Unable to share ticket: $e',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              child: Text('Share / Save Ticket',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.offAllNamed('/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              child: Text('Go to Home',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 🔹 Booking History button
                    ElevatedButton(
                      onPressed: () {
                        Get.toNamed('/bookingHistory');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        child: Text(
                          'Go to Booking History',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}