import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking/controllers/event_controller.dart';
import 'package:event_booking/controllers/booking_controller.dart';
import 'package:event_booking/models/event_model.dart';
import '../../services/custom_snackbar.dart';
import 'package:event_booking/services/alert_dialog_utils.dart';
import 'package:event_booking/controllers/auth_controller.dart';
import 'package:event_booking/views/admin/admin_management_dashboard.dart';
import 'package:event_booking/views/admin/qr_verification_page.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

// 🔹 Event extension for AM/PM formatted date
extension EventExtension on Event {
  String get formattedDate {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}  $hour:$minute $ampm";
  }
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final EventController eventController = Get.put(EventController());
  final BookingController bookingController = Get.put(BookingController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  String adminInviteCode = "ADMIN2025";

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController ticketPriceController = TextEditingController();
  final TextEditingController seatLimitController = TextEditingController();

  late int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadInviteCode();
    addActiveFieldToAdmins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  Future<void> addActiveFieldToAdmins() async {
    final QuerySnapshot adminSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    for (var doc in adminSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('active')) {
        await _firestore.collection('users').doc(doc.id).update({'active': true});
      }
    }
  }

  Future<void> _loadInviteCode() async {
    final doc = await _firestore.collection('config').doc('adminConfig').get();
    if (doc.exists && doc.data()!.containsKey('inviteCode')) {
      setState(() {
        adminInviteCode = doc['inviteCode'];
      });
    }
  }

  Future<void> _updateInviteCode(BuildContext context) async {
    TextEditingController codeController =
    TextEditingController(text: adminInviteCode);

    await Get.defaultDialog(
      title: "Update Admin Invite Code",
      content: TextField(
        controller: codeController,
        decoration: const InputDecoration(
          hintText: "Enter new invite code",
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: "Update",
      textCancel: "Cancel",
      onConfirm: () async {
        String newCode = codeController.text.trim();
        if (newCode.isEmpty) return;

        await _firestore
            .collection('config')
            .doc('adminConfig')
            .set({'inviteCode': newCode});

        setState(() => adminInviteCode = newCode);
        Get.back();

        CustomSnackbar.success('Success', "✅ Invite code updated successfully!");
      },
    );
  }

  void _showAddEventDialog(BuildContext context) {
    titleController.clear();
    descriptionController.clear();
    venueController.clear();
    imageUrlController.clear();
    ticketPriceController.clear();
    seatLimitController.clear();

    DateTime? selectedStartDateTime;
    DateTime? selectedEndDateTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
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
                      initialDate: selectedStartDateTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime ?? DateTime.now()),
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

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    if (selectedStartDateTime == null) return;
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDateTime ?? selectedStartDateTime!,
                      firstDate: selectedStartDateTime!,
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndDateTime ?? selectedStartDateTime!),
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

                const SizedBox(height: 10),
                if (selectedStartDateTime != null)
                  Text("Start: ${formatDateTime(selectedStartDateTime!)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                if (selectedEndDateTime != null)
                  Text("End: ${formatDateTime(selectedEndDateTime!)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    selectedStartDateTime == null) {
                  CustomSnackbar.error('Failed', "⚠️ Please fill all required fields");
                  return;
                }

                String eventId = DateTime.now().millisecondsSinceEpoch.toString();
                Event newEvent = Event(
                  id: eventId,
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: selectedStartDateTime!,
                  endDateTime: selectedEndDateTime,
                  venue: venueController.text,
                  imageUrl: imageUrlController.text.isEmpty ? 'https://via.placeholder.com/150' : imageUrlController.text,
                  ticketPrice: int.tryParse(ticketPriceController.text) ?? 0,
                  seatLimit: int.tryParse(seatLimitController.text) ?? 0,
                );

                await eventController.addEvent(newEvent);

                Get.back();
                CustomSnackbar.success('success', "✅ Event added successfully!");
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event, int index) {
    titleController.text = event.title;
    descriptionController.text = event.description;
    venueController.text = event.venue;
    imageUrlController.text = event.imageUrl;
    ticketPriceController.text = event.ticketPrice.toString();
    seatLimitController.text = event.seatLimit.toString();

    DateTime selectedStartDateTime = event.dateTime;
    DateTime? selectedEndDateTime = event.endDateTime;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
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

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    if (selectedStartDateTime == null) return;
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDateTime ?? selectedStartDateTime,
                      firstDate: selectedStartDateTime,
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndDateTime ?? selectedStartDateTime),
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

                const SizedBox(height: 10),
                Text("Start: ${formatDateTime(selectedStartDateTime)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                if (selectedEndDateTime != null)
                  Text("End: ${formatDateTime(selectedEndDateTime!)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    selectedStartDateTime == null) {
                  CustomSnackbar.error('Failed', "⚠️ Please fill all required fields");
                  return;
                }

                Event updatedEvent = Event(
                  id: event.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: selectedStartDateTime,
                  endDateTime: selectedEndDateTime,
                  venue: venueController.text,
                  imageUrl: imageUrlController.text.isEmpty ? 'https://via.placeholder.com/150' : imageUrlController.text,
                  ticketPrice: int.tryParse(ticketPriceController.text) ?? 0,
                  seatLimit: int.tryParse(seatLimitController.text) ?? 0,
                );

                await eventController.updateEvent(event.id, updatedEvent.toJson());
                Get.back();
                CustomSnackbar.success('success', "✅ Event updated successfully!");
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, String id, int index) async {
    try {
      await eventController.removeEvent(id);
      CustomSnackbar.success('success', "✅ Event deleted successfully");
    } catch (e) {
      CustomSnackbar.error('Failed', "⚠️ Failed to delete event: $e");
    }
  }

  static Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
  String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: Colors.deepPurple,
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
              if (shouldLogout == true) {
                await authController.logout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.deepPurple.shade50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: "Upcoming Events"),
                Tab(text: "Bookings"),
                Tab(text: "Past Events"),
                Tab(text: "Past Bookings"),
                Tab(text: "Admins & Users"),
                Tab(text: "Invite"),
                Tab(text: "QR Verify")
              ],
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [

                // Upcoming Events
                Obx(() {
                  final upcomingEvents = eventController.events
                      .where((e) => (e.endDateTime ?? e.dateTime).isAfter(DateTime.now()))
                      .toList();

                  if (upcomingEvents.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Upcoming Events 😔",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: upcomingEvents.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final event = upcomingEvents[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (event.imageUrl.isNotEmpty)
                                        ? Image.network(
                                      event.imageUrl,
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
                                      },
                                    )
                                        : Image.asset(
                                      'assets/images/placeholder.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditEventDialog(context, event, index),
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
                                        await _deleteEvent(context, event.id, index);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Description: ${event.description}"),
                              Text("Venue: ${event.venue}"),
                              Text("Start: ${formatDateTime(event.dateTime)}"),
                              if (event.endDateTime != null)
                                Text("End: ${formatDateTime(event.endDateTime!)}"),
                              Text("Ticket Price: ৳${event.ticketPrice}"),
                              Text("Seat Limit: ${event.seatLimit}"),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Bookings Tab
                Obx(() {
                  if (bookingController.bookings.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Bookings Yet 😔",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: bookingController.bookings.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final booking = bookingController.bookings[index];

                      final formattedDate =
                      DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookingTime);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    return const Center(
                      child: Text(
                        "No Past Events 😌",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pastEvents.length,
                    itemBuilder: (context, index) {
                      final event = pastEvents[index];
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
                                    child: (event.imageUrl.isNotEmpty)
                                        ? Image.network(
                                      event.imageUrl,
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
                                      },
                                    )
                                        : Image.asset(
                                      'assets/images/placeholder.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.history, color: Colors.black),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Description: ${event.description}"),
                              Text("Venue: ${event.venue}"),
                              Text("Start: ${formatDateTime(event.dateTime)}"),
                              if (event.endDateTime != null)
                                Text("End: ${formatDateTime(event.endDateTime!)}"),
                              Text("Ticket Price: ৳${event.ticketPrice}"),
                              Text("Seat Limit: ${event.seatLimit}"),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                //  Past Bookings Tab
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

                // Admin Management Page
                const AdminManagementDashboardPage(),

                // Invite Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Current Invite Code:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        adminInviteCode,
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _updateInviteCode(context),
                        icon: const Icon(Icons.vpn_key),
                        label: const Text("Update Invite Code"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Verification Tab
                const QRVerificationPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}