import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryLog {
  final String id;
  final String action;
  final String performedBy;
  final DateTime createdAt;

  HistoryLog({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.createdAt,
  });

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      id: json['id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'performed_by': performedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

