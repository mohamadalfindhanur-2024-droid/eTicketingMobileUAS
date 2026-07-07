import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  String id;
  String name;
  String email;
  String role; // 'User', 'Helpdesk', 'Admin'
  String password;
  bool isActive;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
    this.isActive = true,
  });

  UserProfile copyWith({String? name, String? email, String? role, String? password, bool? isActive}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      password: json['password'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'password': password,
      'is_active': isActive,
    };
  }
}

