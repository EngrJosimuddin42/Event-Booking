import 'package:get/get.dart';
import '../views/auth/login_page.dart';
import '../views/auth/signup_page.dart';
import '../views/user/home_page.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/admin/super_admin_dashboard.dart';
import '../services/qr_page.dart';
import 'package:event_booking/views/admin/qr_verification_page.dart';
import 'package:event_booking/views/user/booking_history_page.dart';
class AppRoutes {
  static final routes = [
    // 🔹 Auth Pages
    GetPage(name: '/login', page: () => const LoginPage()),
    GetPage(name: '/signup', page: () => const SignupPage()),

    // 🔹 User Pages
    GetPage(name: '/home', page: () => HomePage()),
    GetPage(name: '/bookingHistory', page: () => BookingHistoryPage()),

    // 🔹 Admin Pages
    GetPage(name: '/admin', page: () => AdminDashboardPage()),
    GetPage(name: '/super_admin', page: () => SuperAdminDashboardPage()),
    GetPage(name: '/qrVerify', page: () => const QRVerificationPage()),
    // 🔹 Other Services
    GetPage(name: '/qr', page: () => QRPage()),

  ];
}