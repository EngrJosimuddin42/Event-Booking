import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:event_booking/controllers/event_controller.dart';
import 'package:event_booking/controllers/booking_controller.dart';
import 'package:event_booking/controllers/auth_controller.dart';
import 'package:event_booking/models/event_model.dart';
import 'package:event_booking/services/alert_dialog_utils.dart';
import 'package:event_booking/views/admin/qr_verification_page.dart';
import '../../services/custom_snackbar.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final EventController eventController = Get.put(EventController());
  final BookingController bookingController = Get.put(BookingController());

  late TabController _tabController;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController ticketPriceController = TextEditingController();
  final TextEditingController seatLimitController = TextEditingController();

  DateTime selectedStartDateTime = DateTime.now();
  DateTime? selectedEndDateTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute $ampm";
  }

  // Add Event Dialog
  void _showAddEventDialog() {
    titleController.clear();
    descriptionController.clear();
    venueController.clear();
    imageUrlController.clear();
    ticketPriceController.clear();
    seatLimitController.clear();
    selectedStartDateTime = DateTime.now();
    selectedEndDateTime = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add New Event"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(titleController, "Title"),
                _buildTextField(descriptionController, "Description"),
                _buildTextField(venueController, "Venue"),
                _buildTextField(imageUrlController, "Image URL"),
                _buildTextField(ticketPriceController, "Ticket Price", isNumber: true),
                _buildTextField(seatLimitController, "Seat Limit", isNumber: true),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
                      );
                      if (pickedTime != null) {
                        selectedStartDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setStateDialog(() {});
                      }
                    }
                  },
                  child: const Text("Pick Event Start Date & Time"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "Start: ${formatDateTime(selectedStartDateTime)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDateTime,
                      firstDate: selectedStartDateTime,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
                      );
                      if (pickedTime != null) {
                        selectedEndDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setStateDialog(() {});
                      }
                    }
                  },
                  child: const Text("Pick Event End Date & Time"),
                ),
                if (selectedEndDateTime != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "End: ${formatDateTime(selectedEndDateTime!)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    venueController.text.isEmpty ||
                    ticketPriceController.text.isEmpty ||
                    seatLimitController.text.isEmpty ||
                    selectedEndDateTime == null) {
                  CustomSnackbar.error('Error', 'Please fill all fields and pick end date & time');
                  return;
                }

                String eventId = DateTime.now().millisecondsSinceEpoch.toString();
                Event newEvent = Event(
                  id: eventId,
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: selectedStartDateTime,
                  endDateTime: selectedEndDateTime,
                  venue: venueController.text,
                  imageUrl: imageUrlController.text.isEmpty
                      ? 'https://via.placeholder.com/150'
                      : imageUrlController.text,
                  ticketPrice: int.tryParse(ticketPriceController.text) ?? 500,
                  seatLimit: int.tryParse(seatLimitController.text) ?? 100,
                );

                await eventController.addEvent(newEvent);
                Get.back();
                CustomSnackbar.success('Success', 'Event added successfully!');
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Event Dialog
  void _showEditEventDialog(Event event) {
    titleController.text = event.title;
    descriptionController.text = event.description;
    venueController.text = event.venue;
    imageUrlController.text = event.imageUrl;
    ticketPriceController.text = event.ticketPrice.toString();
    seatLimitController.text = event.seatLimit.toString();
    selectedStartDateTime = event.dateTime;
    selectedEndDateTime = event.endDateTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Event"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(titleController, "Title"),
                _buildTextField(descriptionController, "Description"),
                _buildTextField(venueController, "Venue"),
                _buildTextField(imageUrlController, "Image URL"),
                _buildTextField(ticketPriceController, "Ticket Price", isNumber: true),
                _buildTextField(seatLimitController, "Seat Limit", isNumber: true),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
                      );
                      if (pickedTime != null) {
                        selectedStartDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setStateDialog(() {});
                      }
                    }
                  },
                  child: const Text("Pick Event Start Date & Time"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "Start: ${formatDateTime(selectedStartDateTime)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDateTime,
                      firstDate: selectedStartDateTime,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
                      );
                      if (pickedTime != null) {
                        selectedEndDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setStateDialog(() {});
                      }
                    }
                  },
                  child: const Text("Pick Event End Date & Time"),
                ),
                if (selectedEndDateTime != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "End: ${formatDateTime(selectedEndDateTime!)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedEndDateTime == null) {
                  CustomSnackbar.error('Error', 'Pick event end date & time');
                  return;
                }

                Event updatedEvent = Event(
                  id: event.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: selectedStartDateTime,
                  endDateTime: selectedEndDateTime,
                  venue: venueController.text,
                  imageUrl: imageUrlController.text.isEmpty
                      ? 'https://via.placeholder.com/150'
                      : imageUrlController.text,
                  ticketPrice: int.tryParse(ticketPriceController.text) ?? 500,
                  seatLimit: int.tryParse(seatLimitController.text) ?? 100,
                );

                await eventController.updateEvent(event.id, updatedEvent.toJson());
                Get.back();
                CustomSnackbar.success('Success', 'Event updated successfully!');
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  // TextField Helper
  static Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
  String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.deepPurple.shade50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: "Upcoming Events"),
                Tab(text: "Bookings"),
                Tab(text: "Past Events"),
                Tab(text: "Past Bookings"),
                Tab(text: "QR Verify")
              ],
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black,
            ),
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming Events
          Obx(() {
            final upcomingEvents = eventController.events
                .where((e) => (e.endDateTime ?? e.dateTime).isAfter(DateTime.now()))
                .toList();
            if (upcomingEvents.isEmpty) {
              return const Center(child: Text("No Upcoming Events 😔", style: TextStyle(fontSize: 16, color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return _buildEventCard(event);
              },
            );
          }),

          // Bookings
          Obx(() {
            if (bookingController.bookings.isEmpty) {
              return const Center(child: Text("No Bookings Yet 😔", style: TextStyle(fontSize: 16, color: Colors.grey)));
            }
            return ListView.builder(
              itemCount: bookingController.bookings.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final booking = bookingController.bookings[index];
                final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookingTime);
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title:  Text('Event: ${booking.eventTitle ?? "N/A"}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                      'Booking ID: ${booking.id}\n'
                          'Email: ${booking.userEmail ?? "N/A"}\n'
                          'User: ${booking.userName ?? "N/A"}\n'
                          'Tickets: ${booking.ticketCount}\n'
                          'Status: ${booking.status}\n'
                          'Event Start: ${formatDate(booking.eventDateTime)}\n'
                          'Event End: ${booking.eventEndDateTime != null ? formatDate(booking.eventEndDateTime!) : "N/A"}\n'
                          'Booking Time: $formattedDate',
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.verified, color: Colors.greenAccent),
                  ),
                );
              },
            );
          }),

          // Past Events
          Obx(() {
            final pastEvents = eventController.events
                .where((e) => (e.endDateTime ?? e.dateTime).isBefore(DateTime.now()))
                .toList();
            if (pastEvents.isEmpty) {
              return const Center(child: Text("No Past Events 😌", style: TextStyle(fontSize: 16, color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pastEvents.length,
              itemBuilder: (context, index) {
                final event = pastEvents[index];
                return _buildEventCard(event, isPast: true);
              },
            );
          }),

          // Past Bookings Tab
          Obx(() {
            final past = bookingController.pastBookings;

            if (past.isEmpty) {
              return const Center(
                child: Text(
                  "No Past Bookings 😌",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: past.length,
              itemBuilder: (context, index) {
                final booking = past[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      'Event: ${booking.eventTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Booking ID: ${booking.id}\n'
                          'User: ${booking.userName}\n'
                          'Tickets: ${booking.ticketCount}\n'
                          'Status: ${booking.status}\n'
                          'Event End: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.eventEndDateTime ?? booking.eventDateTime)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              },
            );
          }),


          // QR Verification
          const QRVerificationPage(),
        ],
      ),
    );
  }

  // Event Card Widget
  Widget _buildEventCard(Event event, {bool isPast = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: event.imageUrl.isNotEmpty
                      ? Image.network(event.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholder.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      })
                      : Image.asset(
                    'assets/images/placeholder.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                ),
                if (!isPast) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditEventDialog(event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text("Are you sure you want to delete this event?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        await eventController.removeEvent(event.id);
                        CustomSnackbar.success('Deleted', 'Event removed successfully!');
                      }
                    },
                  ),
                ] else
                  const Icon(Icons.history, color: Colors.black),
              ],
            ),
            const SizedBox(height: 6),
            Text("Description: ${event.description}"),
            Text("Venue: ${event.venue}"),
            Text("Start: ${formatDateTime(event.dateTime)}"),
            Text("End: ${event.endDateTime != null ? formatDateTime(event.endDateTime!) : 'N/A'}"),
            Text("Ticket Price: ৳${event.ticketPrice}"),
            Text("Seat Limit: ${event.seatLimit}"),
          ],
        ),
      ),
    );
  }
}