import 'package:supabase_flutter/supabase_flutter.dart';
import 'comment.dart';
import 'history_log.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String category; // 'Hardware', 'Software', 'Network'
  final String priority; // 'Low', 'Medium', 'High'
  String status; // 'Open', 'In Progress', 'Resolved', 'Closed'
  final String createdBy;
  String? assignedTo; // Nama helpdesk yang ditugaskan
  final DateTime createdAt;
  DateTime updatedAt;
  String? attachmentName;
  final List<Comment> comments;
  final List<HistoryLog> history;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentName,
    required this.comments,
    required this.history,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    var commentsList = json['comments'] as List? ?? [];
    var historyList = json['history'] as List? ?? [];

    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachmentName: json['attachment_name'] as String?,
      comments: commentsList.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList(),
      history: historyList.map((h) => HistoryLog.fromJson(h as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachment_name': attachmentName,
    };
  }
}

