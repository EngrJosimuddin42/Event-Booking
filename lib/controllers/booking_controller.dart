import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import 'package:flutter/foundation.dart';
class BookingController extends GetxController {
  final bookings = <Booking>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    loadBookings();
  }

  /// 🔹 Firestore থেকে সব বুকিং লোড করা
  Future<void> loadBookings() async {
    try {
      final snapshot = await _firestore.collection('bookings').get();
      final allBookings = snapshot.docs.map((doc) {
        return Booking.fromMap(doc.data(), doc.id);
      }).toList();

      bookings.assignAll(allBookings);
    } catch (e) {
      debugPrint('Failed to load bookings: $e');
    }
  }

  /// 🔹 Event বুক করার ফাংশন (Payment সহ)
  Future<Booking?> bookEvent(
      String eventId,
      int ticketCount,
      String paymentMethod,
      ) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // 🔹 User Details Load
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc['name'] ?? user.email ?? 'Unknown User';
      final userEmail = userDoc['email'] ?? user.email ?? 'unknown@example.com';

      final eventRef = _firestore.collection('events').doc(eventId);

      Booking? newBooking;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) return;

        final eventData = snapshot.data()!;
        int availableSeats =
            eventData['availableSeats'] ?? eventData['seatLimit'] ?? 100;
        int bookedSeats = eventData['bookedSeats'] ?? 0;

        if (availableSeats < ticketCount) return;

        // 🔹 Seat Update
        transaction.update(eventRef, {
          'availableSeats': availableSeats - ticketCount,
          'bookedSeats': bookedSeats + ticketCount,
        });

        // 🔹 Date Convert
        DateTime eventStartDateTime = (eventData['dateTime'] is Timestamp)
            ? (eventData['dateTime'] as Timestamp).toDate()
            : DateTime.tryParse(eventData['dateTime'] ?? '') ??
            DateTime.now();

        DateTime? eventEndDateTime;
        if (eventData['endDateTime'] != null) {
          if (eventData['endDateTime'] is Timestamp) {
            eventEndDateTime =
                (eventData['endDateTime'] as Timestamp).toDate();
          } else if (eventData['endDateTime'] is String &&
              eventData['endDateTime'].isNotEmpty) {
            eventEndDateTime = DateTime.parse(eventData['endDateTime']);
          }
        }

        final bookingId = _firestore.collection('bookings').doc().id;

        // 🔹 New Booking Model Create
        newBooking = Booking(
          id: bookingId,
          eventId: eventId,
          eventTitle: eventData['title'] ?? '',
          userId: user.uid,
          userName: userName,
          userEmail: userEmail,
          ticketCount: ticketCount,
          status: 'confirmed',
          bookingTime: DateTime.now(),
          eventDateTime: eventStartDateTime,
          eventEndDateTime: eventEndDateTime,

          // 🔥 Payment Fields Add
          paymentMethod: paymentMethod,
          paymentStatus: "Paid",
        );

        // 🔹 Firestore এ Save
        transaction.set(
          _firestore.collection('bookings').doc(bookingId),
          newBooking!.toMap(),
        );
      });

      if (newBooking != null) bookings.add(newBooking!);
      return newBooking;

    } catch (e) {
      debugPrint('Booking Failed: $e');
      return null;
    }
  }

  /// 🔹 Booking cancel function
  Future<void> cancelBooking(Booking booking) async {
    try {
      final eventRef = _firestore.collection('events').doc(booking.eventId);
      final bookingRef = _firestore.collection('bookings').doc(booking.id);

      await _firestore.runTransaction((transaction) async {
        final eventSnapshot = await transaction.get(eventRef);
        if (!eventSnapshot.exists) return;

        final eventData = eventSnapshot.data()!;
        int availableSeats =
            eventData['availableSeats'] ?? eventData['seatLimit'] ?? 100;
        int bookedSeats = eventData['bookedSeats'] ?? 0;

        // 🔹 Seat Restore
        transaction.update(eventRef, {
          'availableSeats': availableSeats + booking.ticketCount,
          'bookedSeats': bookedSeats - booking.ticketCount,
        });

        // 🔹 Booking Delete
        transaction.delete(bookingRef);
      });

      // 🔹 Local list থেকে remove
      bookings.removeWhere((b) => b.id == booking.id);

    } catch (e) {
      debugPrint('Cancel Booking Failed: $e');
    }
  }

  /// 🔹 Future Upcoming Bookings (Event ending time > now)
  List<Booking> get upcomingBookings {
    return bookings.where((b) {
      final end = b.eventEndDateTime ?? b.eventDateTime;
      return end.isAfter(DateTime.now());
    }).toList();
  }

  /// 🔹 Past Bookings (Event ending time < now)
  List<Booking> get pastBookings {
    return bookings.where((b) {
      final end = b.eventEndDateTime ?? b.eventDateTime;
      return end.isBefore(DateTime.now());
    }).toList();
  }
}