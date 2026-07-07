import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationItem {
  final String id;
  final String ticketId;
  final String title;
  final String description;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.description,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'title': title,
      'description': description,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

