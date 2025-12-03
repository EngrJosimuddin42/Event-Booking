import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/custom_snackbar.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/admin/super_admin_dashboard.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> appUser = Rx<UserModel?>(null);
  final RxBool _hasNavigated = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(auth.authStateChanges());
    ever(firebaseUser, (User? user) => _handleAuthChanged(user));
  }

  void _handleAuthChanged(User? user) async {
    if (_hasNavigated.value) return;

    if (user == null) {
      _navigateToLogin();
    } else {
      await loadUserData(user.uid);
    }

    _hasNavigated.value = true;
  }

  Future<void> loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        appUser.value = UserModel.fromJson(doc.data() as Map<String, dynamic>);

        // Update last login
        await firestore.collection('users').doc(uid).update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });

        _redirectUser(appUser.value!);
      } else {
        await logout();
      }
    } catch (e) {
      if (Get.context != null) {
        CustomSnackbar.error('Failed', "⚠️ Failed to load user data: $e");
      }
    }
  }

  void _redirectUser(UserModel user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user.role == 'admin') {
        if (user.isSuperAdmin) {
          Get.offAll(() => SuperAdminDashboardPage());
        } else {
          Get.offAll(() => AdminDashboardPage());
        }
      } else {
        Get.offAllNamed('/home');
      }
    });
  }

  Future<void> login(String email, String password) async {
    try {
      UserCredential cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await loadUserData(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => "⚠️ Email not registered.",
        'wrong-password' => "❌ Wrong password.",
        'invalid-email' => "⚠️ Invalid email format.",
        'too-many-requests' => "🚫 Too many attempts. Try later.",
        _ => e.message ?? "Unknown error occurred.",
      };
      if (Get.context != null) CustomSnackbar.error('Failed', message);
    }
  }

  Future<void> logout() async {
    try {
      await auth.signOut();
      appUser.value = null;
      _hasNavigated.value = false;
      _navigateToLogin();
    } catch (e) {
      if (Get.context != null) CustomSnackbar.error('Failed', "Logout failed: $e");
    }
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed('/login');
    });
  }
}