import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/event_controller.dart';
import 'package:event_booking/controllers/auth_controller.dart';
import 'package:event_booking/services/alert_dialog_utils.dart';
import 'booking_page.dart';

class HomePage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final EventController eventController = Get.put(EventController());

  HomePage({super.key});

  String formatDate(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}  $hour:$minute $ampm";
  }

  Widget buildEventCard(context, event) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Event Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (event.imageUrl?.isNotEmpty ?? false)
                  ? Image.network(
                event.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(
                      'assets/images/placeholder.png',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              )
                  : Image.asset(
                'assets/images/placeholder.png',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Description: ${event.description}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("Venue: ${event.venue}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("Event Start: ${formatDate(event.dateTime)}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            if (event.endDateTime != null)
              Text("Event End: ${formatDate(event.endDateTime!)}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("Ticket Price: ৳${event.ticketPrice}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("Seat Limit: ${event.seatLimit}",
                style: const TextStyle(fontWeight: FontWeight.w500)),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Get.to(() => BookingPage (event: event));
                  },
                  child: const Text('Book Now',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),

                  onPressed: () {
                    final shareText = '''
📢 ${event.title}
Description: ${event.description}
Venue: ${event.venue}
Event Start: ${formatDate(event.dateTime)}
${event.endDateTime != null ? "Event End: ${formatDate(event.endDateTime!)}" : ""}
Ticket Price: ৳${event.ticketPrice}
Seat Limit: ${event.seatLimit}
Join this event now! 🎉
                     ''';
                    Share.share(shareText);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Share',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Upcoming Events',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Booking History',
            onPressed: () => Get.toNamed('/bookingHistory'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final shouldLogout = await AlertDialogUtils.showConfirm(
                context: context,
                title: "Confirm Logout",
                content: const Text("Are you sure you want to log out?"),
                confirmColor: Colors.red,
                cancelColor: Colors.black,
                confirmText: "Logout",
                cancelText: "Cancel",
              );
              if (shouldLogout == true) await authController.logout();
            },
          ),
        ],
      ),
      body: Obx(() {
        final upcomingEvents = eventController.events
            .where((e) => e.endDateTime == null
            ? e.dateTime.isAfter(DateTime.now())
            : e.endDateTime!.isAfter(DateTime.now())
        )
            .toList();

        if (upcomingEvents.isEmpty) {
          return const Center(
            child: Text('No upcoming events 😔',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: upcomingEvents.length,
          itemBuilder: (context, index) =>
              buildEventCard(context, upcomingEvents[index]),
        );
      }),
    );
  }
}