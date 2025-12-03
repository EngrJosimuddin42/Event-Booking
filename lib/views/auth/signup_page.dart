import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../services/custom_snackbar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final authController = Get.put(AuthController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool isLoading = false;
  String? selectedRole = 'user';

  String? emailError;
  String? passwordError;

  void _validateEmail(String value) {
    print("📧 Validating email: $value");
    if (value.contains(RegExp(r'[A-Z]'))) {
      setState(() => emailError = "❌ Email must be lowercase");
      print("❌ Invalid: contains uppercase");
    } else if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
        .hasMatch(value)) {
      setState(() => emailError = "❌ Invalid email format");
      print("❌ Invalid email format");
    } else {
      setState(() => emailError = null);
      print("✅ Email valid");
    }
  }

  void _validatePassword(String value) {
    print("🔒 Validating password...");
    if (value.isEmpty) {
      setState(() => passwordError = "❌ Password is required");
      print("❌ Password empty");
    } else if (value.length < 6) {
      setState(() => passwordError = "🔒 Minimum 6 characters required");
      print("❌ Too short");
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      setState(() => passwordError = "🔢 Must contain a number");
      print("❌ No number");
    } else if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      setState(() => passwordError = "🅰️ Must contain a letter");
      print("❌ No letter");
    } else {
      setState(() => passwordError = null);
      print("✅ Password valid");
    }
  }

  void _signUp() async {
    print("🚀 Signup started");
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      print("⚠️ One or more fields empty");
      CustomSnackbar.error(
          'Failed',
          "⚠️ Fill all fields before signup!"
      );
      return;
    }

    String? enteredAdminCode;
    if (selectedRole == 'admin') {
      print("👑 Admin signup selected, checking invite code...");
      String adminInviteCode = '';
      try {
        final doc =
        await _firestore.collection('config').doc('adminConfig').get();
        adminInviteCode =
        doc.exists ? doc['inviteCode'] ?? "ADMIN2025" : "ADMIN2025";
        print("✅ Admin invite code fetched: $adminInviteCode");
      } catch (e) {
        print("❌ Failed to fetch admin invite code: $e");
        CustomSnackbar.error('Failed', "❌ Failed to fetch admin invite code: $e");
        return;
      }

      await showDialog(
        context: context,
        builder: (context) {
          TextEditingController codeController = TextEditingController();
          return AlertDialog(
            title: const Text("Admin Invite Code"),
            content:
            TextField(controller: codeController, decoration: const InputDecoration(hintText: "Enter admin invite code")),
            actions: [
              TextButton(
                onPressed: () {
                  enteredAdminCode = codeController.text.trim();
                  Navigator.of(context).pop();
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );

      print("🔑 Entered admin code: $enteredAdminCode");
      if (enteredAdminCode != adminInviteCode) {
        print("❌ Invalid admin invite code");
        CustomSnackbar.error(
            'Failed',
            "❌ Invalid admin invite code!"
        );
        return;
      } else {
        print("✅ Admin invite code matched");
      }
    }

    _continueSignUp(enteredAdminCode);
  }

  void _continueSignUp(String? enteredAdminCode) async {
    print("➡️ Continuing signup...");
    _validateEmail(emailController.text);
    _validatePassword(passwordController.text);

    if (emailError != null || passwordError != null) {
      print("❌ Validation failed, stopping signup");
      return;
    }

    setState(() => isLoading = true);
    print("⏳ Creating FirebaseAuth user...");

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User user = userCredential.user!;
      print("✅ FirebaseAuth user created: ${user.uid}");

      String role = 'user';
      bool isSuperAdmin = false;

      print("🔍 Checking existing admins in Firestore...");
      final adminSnapshot =
      await _firestore.collection('users').where('role', isEqualTo: 'admin').get();

      if (adminSnapshot.docs.isEmpty) {
        print("🟣 No admin found — making this user SUPER ADMIN");
        isSuperAdmin = true;
        role = 'admin';
      } else if (selectedRole == 'admin' && enteredAdminCode != null) {
        print("🟢 Valid admin code, assigning admin role");
        role = 'admin';
      } else {
        print("👤 Regular user signup");
      }

      print("🟡 Saving user to Firestore...");
      await _firestore.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'email': user.email,
        'role': role,
        'isSuperAdmin': isSuperAdmin,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ User saved in Firestore successfully");

      print("🔁 Loading user data...");
      await authController.loadUserData(user.uid);
      print("✅ User data loaded and navigation done");

    } on FirebaseAuthException catch (e) {
      print("🔥 FirebaseAuthException: ${e.code} - ${e.message}");
      String message = switch (e.code) {
        'email-already-in-use' => 'Email already in use.',
        'weak-password' => 'Password is too weak.',
        _ => e.message ?? 'An error occurred.',
      };
      CustomSnackbar.error('Failed', "❌ Signup failed: $message");
    } catch (e) {
      print("💥 Unexpected error during signup: $e");
      CustomSnackbar.error('Failed', "❌ Signup failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
      print("🏁 Signup process finished");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Create Your Account',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              onChanged: _validateEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: emailError,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              onChanged: _validatePassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: passwordError,
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 400,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: selectedRole,
                    hint: const Text("Select Role"),
                    items: ["User", "Admin"]
                        .map((role) => DropdownMenuItem<String>(
                      value: role.toLowerCase(),
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedRole = val);
                      print("🔽 Role selected: $val");
                    },
                    dropdownStyleData: DropdownStyleData(
                      width: 190,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      offset: const Offset(200, 0),
                      elevation: 4,
                    ),
                    buttonStyleData: ButtonStyleData(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                      iconSize: 30,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            isLoading
                ? const CircularProgressIndicator(color: Colors.deepPurple)
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                print("🔙 Going back to login page");
                Navigator.pop(context);
              },
              child: const Text(
                "Already have an account? Log In",
                style: TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}