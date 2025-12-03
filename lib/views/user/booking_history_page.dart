import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:event_booking/controllers/booking_controller.dart';
import 'package:event_booking/models/booking_model.dart';
import 'package:event_booking/services/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:event_booking/services/qr_page.dart';

class BookingHistoryPage extends StatelessWidget {
  final BookingController bookingController = Get.find<BookingController>();

  BookingHistoryPage({super.key});

  String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  bool isUpcoming(Booking b) {
    if (b.eventEndDateTime != null) {
      return b.eventEndDateTime!.isAfter(DateTime.now());
    }
    return b.eventDateTime.isAfter(DateTime.now());
  }

  bool isPast(Booking b) => !isUpcoming(b);

  /// ====== Cancel Allowed Logic ======
  bool canCancel(Booking booking) {
    final now = DateTime.now();
    final eventStart = booking.eventDateTime;

    if (eventStart == null) return false;

    // Event শুরু হওয়ার 1 ঘণ্টা আগে পর্যন্ত cancel allowed
    final cancelLimit = eventStart.subtract(const Duration(hours: 1));

    return now.isBefore(cancelLimit);
  }

  Widget buildBookingList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'No bookings 😔',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        final showCancelButton =
            isUpcoming(booking) && booking.status != "cancelled";

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event: ${booking.eventTitle ?? "N/A"}',
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('Booking ID: ${booking.id}'),
                Text('Email: ${booking.userEmail ?? "N/A"}'),
                Text('User: ${booking.userName ?? "N/A"}'),
                Text('Tickets: ${booking.ticketCount}'),
                Text('Payment Method: ${booking.paymentMethod ?? "N/A"}'),
                Text('Status: ${booking.status}'),
                Text('Event Start: ${formatDate(booking.eventDateTime)}'),
                Text(
                  'Event End: ${booking.eventEndDateTime != null ? formatDate(booking.eventEndDateTime!) : "N/A"}',
                ),
                Text('Booking Time: ${formatDate(booking.bookingTime)}'),
                const SizedBox(height: 8),

                /// ====== BUTTONS ======
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// QR BUTTON
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.indigo),
                      tooltip: 'View QR Code',
                      onPressed: () {
                        Get.to(() => QRPage(), arguments: booking);
                      },
                    ),

                    /// CANCEL BUTTON (Only for upcoming + not cancelled)
                    if (showCancelButton)
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color:
                          canCancel(booking) ? Colors.red : Colors.grey,
                        ),
                        tooltip: canCancel(booking)
                            ? 'Cancel Booking'
                            : 'Cancellation Time Over',
                        onPressed: canCancel(booking)
                            ? () async {
                          bool? confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Cancel Booking"),
                                content: const Text(
                                    "Are you sure you want to cancel this booking?"),
                                actions: [
                                  TextButton(
                                    child: const Text("No"),
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                  ),
                                  ElevatedButton(
                                    child: const Text("Yes"),
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await bookingController
                                .cancelBooking(booking);
                            CustomSnackbar.success(
                              'Cancelled',
                              'Booking has been cancelled.',
                            );
                          }
                        }
                            : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Booking History'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          actions: [
            IconButton(
              icon: const Text('🔁', style: TextStyle(fontSize: 20)),
              tooltip: 'Refresh',
              onPressed: () async {
                await bookingController.loadBookings();
                CustomSnackbar.success(
                    'Refreshed', 'Booking list updated!');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
          ),
        ),
        body: Obx(() {
          final upcomingBookings = bookingController.bookings
              .where((b) => isUpcoming(b))
              .toList();

          final pastBookings =
          bookingController.bookings.where((b) => isPast(b)).toList();

          return TabBarView(
            children: [
              buildBookingList(upcomingBookings),
              buildBookingList(pastBookings),
            ],
          );
        }),
      ),
    );
  }
}