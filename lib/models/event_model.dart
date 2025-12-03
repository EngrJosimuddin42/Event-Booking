class Event {
  String id;
  String title;
  String description;
  DateTime dateTime;
  DateTime? endDateTime;
  String venue;
  String imageUrl;
  int seatLimit;
  int ticketPrice;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.endDateTime,
    required this.venue,
    required this.imageUrl,
    required this.seatLimit,
    required this.ticketPrice,
  });

  /// 🔹 JSON থেকে Event তৈরি
  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime? parsedEndDate;
    if (json['endDateTime'] != null && json['endDateTime'] != '') {
      parsedEndDate = DateTime.tryParse(json['endDateTime']);
    }

    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      endDateTime: parsedEndDate,
      venue: json['venue'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      seatLimit: json['seatLimit'] ?? 100,
      ticketPrice: json['ticketPrice'] ?? 500,
    );
  }

  /// 🔹 Event কে JSON এ রূপান্তর
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'venue': venue,
      'imageUrl': imageUrl,
      'seatLimit': seatLimit,
      'ticketPrice': ticketPrice,
    };
  }

  /// 🔹 AM/PM ফরম্যাটে তারিখ ও সময়
  String get formattedDate {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "$day/$month/$year  $hour:$minute $ampm";
  }

  /// 🔹 ইভেন্ট কি চলবে (Upcoming) check
  bool get isUpcoming {
    if (endDateTime != null) {
      return endDateTime!.isAfter(DateTime.now());
    }
    return dateTime.isAfter(DateTime.now());
  }

  /// 🔹 ইভেন্ট কি শেষ হয়ে গেছে (Past)
  bool get isPast => !isUpcoming;
}