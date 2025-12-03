import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import 'package:event_booking/controllers/booking_controller.dart';
import '../../services/payment_service.dart';
import '../../services/custom_snackbar.dart';
import 'package:event_booking/services/qr_page.dart';

class BookingPage extends StatefulWidget {
  final Event event;
  BookingPage({Key? key, required this.event}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int ticketCount = 0;
  final BookingController bookingController = Get.put(BookingController());
  int remainingSeats = 0;
  late Stream<DocumentSnapshot> eventStream;

  @override
  void initState() {
    super.initState();

    eventStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots();

    eventStream.listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final totalSeats = data['seatLimit'] ?? 100;
        final bookedSeats = data['bookedSeats'] ?? 0;

        setState(() {
          remainingSeats = totalSeats - bookedSeats;
          if (ticketCount > remainingSeats) ticketCount = remainingSeats;
        });
      }
    });
  }

  Future<void> _startPayment() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackbar.error('Not Logged In', 'Please login to book tickets.');
      return;
    }

    await Get.to(() => PaymentService(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      totalAmount: ticketCount * widget.event.ticketPrice.toDouble(),
      onPaymentSuccess: (paymentMethod) async {
        // 🔹 Booking after payment
        final bookingResult = await bookingController.bookEvent(
          widget.event.id,
          ticketCount,
          paymentMethod,
        );

        if (bookingResult != null) {
          CustomSnackbar.success(
              'Booking Successful', 'Your booking has been confirmed.');

          // 🔹 Navigate to QRPage
          Get.off(() => QRPage(), arguments: bookingResult);
        } else {
          CustomSnackbar.error(
              'Booking Failed', 'Unable to complete your booking.');
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = ticketCount * widget.event.ticketPrice.toDouble();
    int availableAfterSelect = remainingSeats - ticketCount;
    if (availableAfterSelect < 0) availableAfterSelect = 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text('Book Tickets'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(widget.event.title,
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Ticket price + remaining seats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ticket Price',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700])),
                          const SizedBox(height: 4),
                          Text('৳${widget.event.ticketPrice}',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remaining Seats',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700])),
                          const SizedBox(height: 4),
                          Text('$availableAfterSelect',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: availableAfterSelect > 0
                                      ? Colors.green
                                      : Colors.red)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Ticket counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (ticketCount > 0) {
                              setState(() {
                                ticketCount--;
                              });
                            }
                          },
                          color: Colors.redAccent,
                          iconSize: 32,
                        ),
                        SizedBox(width: 10),
                        Text('$ticketCount',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (ticketCount < remainingSeats) {
                              setState(() {
                                ticketCount++;
                              });
                            } else {
                              CustomSnackbar.error(
                                  "Limit Reached", "No more tickets available");
                            }
                          },
                          color: Colors.green,
                          iconSize: 32,
                        ),
                      ]),
                      Text('Total: ৳$totalPrice',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (remainingSeats == 0 || ticketCount == 0)
                          ? null
                          : _startPayment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(
                          remainingSeats == 0
                              ? 'Sold Out'
                              : 'Confirm Booking',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}