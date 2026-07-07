import 'package:supabase_flutter/supabase_flutter.dart';

class Comment {
  final String id;
  final String userName;
  final String userRole;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      userRole: json['user_role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_role': userRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

