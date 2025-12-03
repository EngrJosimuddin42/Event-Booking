import 'package:cloud_firestore/cloud_firestore.dart';
class Booking {
  String id;
  String eventId;
  String userId;
  String? userName;
  String? userEmail;
  int ticketCount;
  String status;
  DateTime bookingTime;
  DateTime eventDateTime;
  DateTime? eventEndDateTime;
  String? eventTitle;

  // ✅ Payment info
  String? paymentMethod;
  String paymentStatus;

  Booking({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketCount,
    required this.eventDateTime,
    this.eventEndDateTime,
    this.status = 'confirmed',
    this.userName,
    this.userEmail,
    this.eventTitle,
    this.paymentMethod,
    this.paymentStatus = 'Pending',
    DateTime? bookingTime,
  }) : bookingTime = bookingTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'ticketCount': ticketCount,
      'status': status,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'eventEndDateTime': eventEndDateTime != null ? Timestamp.fromDate(eventEndDateTime!) : null,
      'eventTitle': eventTitle,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedEventDate;
    DateTime? parsedEndDate;

    if (map['eventDateTime'] is Timestamp) {
      parsedEventDate = (map['eventDateTime'] as Timestamp).toDate();
    } else if (map['eventDateTime'] is String) {
      parsedEventDate = DateTime.tryParse(map['eventDateTime'] ?? '') ?? DateTime.now();
    } else {
      parsedEventDate = DateTime.now();
    }

    if (map['eventEndDateTime'] != null) {
      if (map['eventEndDateTime'] is Timestamp) {
        parsedEndDate = (map['eventEndDateTime'] as Timestamp).toDate();
      } else if (map['eventEndDateTime'] is String) {
        parsedEndDate = DateTime.tryParse(map['eventEndDateTime'] ?? '');
      }
    }

    return Booking(
      id: docId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      userEmail: map['userEmail'],
      ticketCount: map['ticketCount'] ?? 0,
      status: map['status'] ?? 'confirmed',
      bookingTime: map['bookingTime'] is Timestamp
          ? (map['bookingTime'] as Timestamp).toDate()
          : DateTime.tryParse(map['bookingTime'] ?? '') ?? DateTime.now(),
      eventDateTime: parsedEventDate,
      eventEndDateTime: parsedEndDate,
      eventTitle: map['eventTitle'],
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'] ?? 'Pending',
    );
  }

  bool get isUpcoming {
    if (eventEndDateTime != null) {
      return eventEndDateTime!.isAfter(DateTime.now());
    }
    return eventDateTime.isAfter(DateTime.now());
  }

  bool get isPast => !isUpcoming;
}