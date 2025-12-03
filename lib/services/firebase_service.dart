import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/booking_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Save Booking
  Future<void> saveBooking(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).set({
      'id': booking.id,
      'eventId': booking.eventId,
      'userId': booking.userId,
      'ticketCount': booking.ticketCount,
      'bookingTime': DateTime.now().toIso8601String(),
    });
  }

  /// 🔹 Save User
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
    });
  }

  /// 🔹 Get User by UID
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      return UserModel(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'user',
      );
    }
    return null;
  }

  /// 🔹 Save Event
  Future<void> saveEvent(Event event) async {
    await _db.collection('events').doc(event.id).set({
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'dateTime': event.dateTime.toIso8601String(),
      'venue': event.venue,
      'imageUrl': event.imageUrl,
      'ticketPrice': event.ticketPrice,
      'seatLimit': event.seatLimit,
      'bookedSeats': 0,
    });
  }

  /// 🔹 Get Event by ID
  Future<Event?> getEvent(String eventId) async {
    DocumentSnapshot doc = await _db.collection('events').doc(eventId).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      return Event(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        dateTime: DateTime.parse(data['dateTime']),
        venue: data['venue'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        ticketPrice: data['ticketPrice'] ?? 500,
        seatLimit: data['seatLimit'] ?? 100,
      );
    }
    return null;
  }
}