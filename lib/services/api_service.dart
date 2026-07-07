import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_profile.dart';
import '../data/models/ticket.dart';
import '../data/models/comment.dart';
import '../data/models/history_log.dart';
import '../data/models/notification_item.dart';
import '../core/state/global_state.dart';

class ApiService {
  static Future<Map<String, dynamic>?> syncData() async {
    try {
      final client = Supabase.instance.client;
      final usersRes = await client.from('users').select();
      final ticketsRes = await client.from('tickets').select('*, comments(*), history:history_logs(*)');
      final notificationsRes = await client.from('notifications').select();

      return {
        'status': 'success',
        'users': usersRes,
        'tickets': ticketsRes,
        'notifications': notificationsRes,
      };
    } catch (e) {
      debugPrint('Error syncData Supabase: $e');
    }
    return null;
  }

  static Future<bool> register(UserProfile user) async {
    try {
      final client = Supabase.instance.client;
      await client.from('users').insert(user.toJson());
      return true;
    } catch (e) {
      debugPrint('Error register Supabase: $e');
    }
    return false;
  }

  static Future<bool> createTicket(Ticket ticket) async {
    try {
      final client = Supabase.instance.client;
      await client.from('tickets').insert(ticket.toJson());
      return true;
    } catch (e) {
      debugPrint('Error createTicket Supabase: $e');
    }
    return false;
  }

  static Future<bool> updateTicket(Ticket ticket) async {
    try {
      final client = Supabase.instance.client;
      await client.from('tickets').update({
        'assigned_to': ticket.assignedTo,
        'status': ticket.status,
        'updated_at': ticket.updatedAt.toIso8601String(),
      }).eq('id', ticket.id);
      return true;
    } catch (e) {
      debugPrint('Error updateTicket Supabase: $e');
    }
    return false;
  }

  static Future<bool> addComment(String ticketId, Comment comment) async {
    try {
      final client = Supabase.instance.client;
      final data = comment.toJson();
      data['ticket_id'] = ticketId;
      await client.from('comments').insert(data);
      return true;
    } catch (e) {
      debugPrint('Error addComment Supabase: $e');
    }
    return false;
  }

  static Future<bool> addHistory(String ticketId, HistoryLog log) async {
    try {
      final client = Supabase.instance.client;
      final data = log.toJson();
      data['ticket_id'] = ticketId;
      await client.from('history_logs').insert(data);
      return true;
    } catch (e) {
      debugPrint('Error addHistory Supabase: $e');
    }
    return false;
  }

  static Future<bool> updateUser(UserProfile user) async {
    try {
      final client = Supabase.instance.client;
      await client.from('users').update({
        'role': user.role,
        'is_active': user.isActive,
      }).eq('email', user.email);
      return true;
    } catch (e) {
      debugPrint('Error updateUser Supabase: $e');
    }
    return false;
  }

  static Future<bool> addNotification(NotificationItem notif) async {
    try {
      final client = Supabase.instance.client;
      await client.from('notifications').insert(notif.toJson());
      return true;
    } catch (e) {
      debugPrint('Error addNotification Supabase: $e');
    }
    return false;
  }

  static Future<bool> readNotifications() async {
    try {
      final client = Supabase.instance.client;
      await client.from('notifications').update({'is_read': true}).neq('id', '');
      return true;
    } catch (e) {
      debugPrint('Error readNotifications Supabase: $e');
    }
    return false;
  }
}
