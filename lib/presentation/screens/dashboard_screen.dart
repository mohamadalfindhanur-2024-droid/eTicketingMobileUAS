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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<UserProfile>(
          valueListenable: profileNotifier,
          builder: (context, user, _) {
            return ValueListenableBuilder<List<Ticket>>(
              valueListenable: ticketsNotifier,
              builder: (context, allTickets, _) {
                // Saring tiket berdasarkan peran
                final userTickets = user.role == 'User'
                    ? allTickets.where((t) => t.createdBy == user.name).toList()
                    : user.role == 'Helpdesk'
                        ? allTickets.where((t) => t.assignedTo == user.name).toList()
                        : allTickets; // Admin sees all

                final totalCount = userTickets.length;
                final openCount = userTickets.where((t) => t.status == 'Open').length;
                final progressCount = userTickets.where((t) => t.status == 'In Progress').length;
                final resolvedCount = userTickets.where((t) => t.status == 'Resolved').length;

                // Urutkan tiket terbaru untuk preview (max 3)
                final recentTickets = List<Ticket>.from(userTickets)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final previewTickets = recentTickets.take(3).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(color: isDark ? slateGray : Colors.grey.shade500, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Halo, ${user.name.split(' ')[0]}!',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (_, mode, __) {
                                return IconButton(
                                  icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_outlined),
                                  onPressed: () {
                                    themeNotifier.value = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                                  onPressed: () => context.push('/notifications'),
                                ),
                                ValueListenableBuilder<List<NotificationItem>>(
                                  valueListenable: notificationsNotifier,
                                  builder: (_, notifs, __) {
                                    final unread = notifs.where((n) => !n.isRead).length;
                                    if (unread == 0) return const SizedBox();
                                    return Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: dangerRed, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                        child: Center(
                                          child: Text(
                                            '$unread',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grid Kartu Statistik
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          context,
                          user.role == 'Admin'
                              ? 'Total Tiket Sistem'
                              : user.role == 'Helpdesk'
                                  ? 'Tiket Ditugaskan'
                                  : 'Total Tiket Anda',
                          '$totalCount',
                          primaryBlue,
                          Icons.confirmation_number_outlined,
                        ),
                        _buildStatCard(context, 'Status Open', '$openCount', getStatusColor('Open'), Icons.trip_origin_rounded),
                        _buildStatCard(context, 'In Progress', '$progressCount', getStatusColor('In Progress'), Icons.query_builder_rounded),
                        _buildStatCard(context, 'Resolved', '$resolvedCount', getStatusColor('Resolved'), Icons.check_circle_outline_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grafik Mingguan Mockup
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Volume Tiket Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('7 Hari Terakhir', style: TextStyle(color: isDark ? slateGray : Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildChartBar('Sen', 30),
                                _buildChartBar('Sel', 55),
                                _buildChartBar('Rab', 25),
                                _buildChartBar('Kam', 85, true),
                                _buildChartBar('Jum', 45),
                                _buildChartBar('Sab', 15),
                                _buildChartBar('Min', 20),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preview Daftar Tiket Terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user.role == 'Admin'
                              ? 'Semua Tiket Terbaru'
                              : user.role == 'Helpdesk'
                                  ? 'Tiket Baru Ditugaskan'
                                  : 'Tiket Terbaru Anda',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.go('/tickets'),
                          child: const Text('Lihat Semua', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (previewTickets.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text('Tidak ada tiket yang terdaftar.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...previewTickets.map((ticket) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTicketListItem(context, ticket),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore ⛅';
    return 'Selamat Malam 🌙';
  }

  Widget _buildStatCard(BuildContext context, String title, String count, Color accentColor, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : darkNavy),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              )
            ],
          ),
          Text(
            title,
            style: TextStyle(color: isDark ? slateGray : slateGray, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double heightPercentage, [bool isActive = false]) {
    return Column(
      children: [
        Container(
          width: 14,
          height: heightPercentage,
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : primaryBlue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTicketListItem(BuildContext context, Ticket ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt_long_rounded, color: isDark ? slateGray : Colors.grey),
        ),
        title: Text(
          ticket.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(ticket.id, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 8),
              Text('•', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 8),
              Text(ticket.category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        trailing: CustomBadge(text: ticket.status, color: getStatusColor(ticket.status)),
        onTap: () => context.push('/ticket/${ticket.id}'),
      ),
    );
  }
}

// -- SCREEN: TICKET LIST (SEARCH & FILTER) --
