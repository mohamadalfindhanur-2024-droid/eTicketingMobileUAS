import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/global_state.dart';
import '../../services/api_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/ticket.dart';
import '../../data/models/comment.dart';
import '../../data/models/history_log.dart';
import '../../data/models/notification_item.dart';
import '../../presentation/widgets/custom_badge.dart';
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              // Tampilkan loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              final success = await ApiService.readNotifications();
              if (context.mounted) Navigator.pop(context); // Tutup loading

              if (success) {
                final list = notificationsNotifier.value;
                for (var n in list) {
                  n.isRead = true;
                }
                notificationsNotifier.value = [...list];
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua notifikasi ditandai dibaca'), backgroundColor: successGreen),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menandai dibaca di MySQL.'), backgroundColor: dangerRed),
                  );
                }
              }
            },
            child: const Text('Tandai semua', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: ValueListenableBuilder<List<NotificationItem>>(
        valueListenable: notificationsNotifier,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Tidak ada notifikasi.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotifItem(context, notif, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, NotificationItem notif, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.isRead
            ? (isDark ? cardDark : Colors.white)
            : (isDark ? primaryBlue.withOpacity(0.12) : primaryBlue.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead ? Colors.grey.withOpacity(0.2) : primaryBlue.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Tandai notif ini sudah dibaca
          final list = notificationsNotifier.value;
          final idx = list.indexWhere((n) => n.id == notif.id);
          if (idx != -1) {
            list[idx].isRead = true;
            notificationsNotifier.value = [...list];
          }
          // Navigasi ke detail tiket
          context.push('/ticket/${notif.ticketId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: notif.isRead ? Colors.grey : primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.description,
                      style: TextStyle(color: isDark ? slateGray : Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateDetailed(notif.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    )
                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateDetailed(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month - 1]}, $time';
  }
}

// -- SCREEN: PROFILE --
