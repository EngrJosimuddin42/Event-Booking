import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'package:flutter/foundation.dart';

class EventController extends GetxController {
  RxList<Event> events = <Event>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    listenToEvents();
  }

  /// 🔹 Firestore থেকে রিয়েলটাইম ইভেন্ট ডাটা শোনা
  void listenToEvents() {
    _firestore.collection('events').snapshots().listen((snapshot) {
      events.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Event.fromJson(data);
      }).toList();
    }, onError: (e) {
      debugPrint("Error listening to events: $e");
    });
  }

  /// 🔹 নতুন ইভেন্ট যোগ করা (UI auto update হবে)
  Future<void> addEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).set(event.toJson());
    } catch (e) {
      debugPrint("Error adding event: $e");
    }
  }

  /// 🔹 ইভেন্ট আপডেট করা (UI auto update হবে)
  Future<void> updateEvent(String id, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('events').doc(id).update(updatedData);
    } catch (e) {
      debugPrint("Error updating event: $e");
    }
  }

  /// 🔹 ইভেন্ট মুছে ফেলা (UI auto remove হবে)
  Future<void> removeEvent(String id) async {
    try {
      await _firestore.collection('events').doc(id).delete();
    } catch (e) {
      debugPrint("Error removing event: $e");
    }
  }
}