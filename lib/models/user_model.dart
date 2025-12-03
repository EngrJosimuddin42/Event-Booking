import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String name;
  String email;
  String role;
  bool isSuperAdmin;
  bool active;
  DateTime? createdAt;
  DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.isSuperAdmin = false,
    this.active = true,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      lastLogin: json['lastLogin'] != null
          ? (json['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isSuperAdmin': isSuperAdmin,
      'active': active,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }
}