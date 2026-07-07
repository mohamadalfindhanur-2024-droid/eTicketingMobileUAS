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
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  void _addComment(Ticket ticket) async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    final currentUser = profileNotifier.value;

    final comment = Comment(
      id: 'C-${DateTime.now().millisecondsSinceEpoch}',
      userName: currentUser.name,
      userRole: currentUser.role,
      content: text,
      createdAt: DateTime.now(),
    );

    final historyLog = HistoryLog(
      id: 'H-${DateTime.now().millisecondsSinceEpoch}',
      action: 'Mengirim komentar: "$text"',
      performedBy: currentUser.name,
      createdAt: DateTime.now(),
    );

    // Kirim notifikasi jika bukan pembuat tiket yang mengirim komentar
    NotificationItem? notifItem;
    if (currentUser.name != ticket.createdBy) {
      notifItem = NotificationItem(
        id: 'N-${DateTime.now().millisecondsSinceEpoch}',
        ticketId: ticket.id,
        title: 'Komentar Baru di ${ticket.id}',
        description: '${currentUser.name} menanggapi tiket Anda.',
        isRead: false,
        createdAt: DateTime.now(),
      );
    }

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Simpan ke Supabase
    final successComment = await ApiService.addComment(ticket.id, comment);
    final successHistory = await ApiService.addHistory(ticket.id, historyLog);
    if (notifItem != null) {
      await ApiService.addNotification(notifItem);
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    if (successComment && successHistory) {
      final tickets = ticketsNotifier.value;
      final idx = tickets.indexWhere((t) => t.id == ticket.id);
      if (idx != -1) {
        tickets[idx].comments.add(comment);
        tickets[idx].history.add(historyLog);
        tickets[idx].updatedAt = DateTime.now();
        ticketsNotifier.value = [...tickets];

        if (notifItem != null) {
          final notifs = notificationsNotifier.value;
          notificationsNotifier.value = [notifItem, ...notifs];
        }
      }
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan komentar ke database Supabase.'), backgroundColor: dangerRed),
      );
    }
  }

  void _changeStatus(Ticket ticket, String newStatus) async {
    final currentUser = profileNotifier.value;
    final oldStatus = ticket.status;
    if (oldStatus == newStatus) return;

    // Persiapan data
    ticket.status = newStatus;
    ticket.updatedAt = DateTime.now();

    final historyLog = HistoryLog(
      id: 'H-${DateTime.now().millisecondsSinceEpoch}',
      action: 'Mengubah status dari $oldStatus ke $newStatus',
      performedBy: currentUser.name,
      createdAt: DateTime.now(),
    );

    final notifItem = NotificationItem(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: ticket.id,
      title: 'Status Tiket ${ticket.id} Diperbarui',
      description: 'Status tiket "${ticket.title}" berubah menjadi $newStatus.',
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Simpan ke Supabase
    final successUpdate = await ApiService.updateTicket(ticket);
    final successHistory = await ApiService.addHistory(ticket.id, historyLog);
    await ApiService.addNotification(notifItem);

    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    if (successUpdate && successHistory) {
      final tickets = ticketsNotifier.value;
      final idx = tickets.indexWhere((t) => t.id == ticket.id);
      if (idx != -1) {
        tickets[idx].status = newStatus;
        tickets[idx].history.add(historyLog);
        tickets[idx].updatedAt = DateTime.now();
        ticketsNotifier.value = [...tickets];

        final notifs = notificationsNotifier.value;
        notificationsNotifier.value = [notifItem, ...notifs];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status tiket berhasil diubah menjadi $newStatus'), backgroundColor: successGreen),
      );
    } else {
      // Rollback local status
      ticket.status = oldStatus;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status ke database Supabase.'), backgroundColor: dangerRed),
      );
    }
  }

  void _assignHelpdesk(Ticket ticket, String helpdeskName) async {
    final currentUser = profileNotifier.value;
    final oldStatus = ticket.status;
    final oldAssigned = ticket.assignedTo;

    // Persiapan data
    ticket.assignedTo = helpdeskName;
    ticket.status = 'In Progress';
    ticket.updatedAt = DateTime.now();

    final historyLog = HistoryLog(
      id: 'H-${DateTime.now().millisecondsSinceEpoch}',
      action: 'Ditugaskan kepada $helpdeskName (Status otomatis diubah dari $oldStatus ke In Progress)',
      performedBy: currentUser.name,
      createdAt: DateTime.now(),
    );

    final notif1 = NotificationItem(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}-1',
      ticketId: ticket.id,
      title: 'Tugas Tiket Baru',
      description: 'Anda telah ditugaskan untuk menangani tiket ${ticket.id} oleh Admin.',
      isRead: false,
      createdAt: DateTime.now(),
    );

    final notif2 = NotificationItem(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}-2',
      ticketId: ticket.id,
      title: 'Status Tiket ${ticket.id} Diperbarui',
      description: 'Status tiket "${ticket.title}" berubah menjadi In Progress.',
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Simpan ke Supabase
    final successUpdate = await ApiService.updateTicket(ticket);
    final successHistory = await ApiService.addHistory(ticket.id, historyLog);
    await ApiService.addNotification(notif1);
    await ApiService.addNotification(notif2);

    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    if (successUpdate && successHistory) {
      final tickets = ticketsNotifier.value;
      final idx = tickets.indexWhere((t) => t.id == ticket.id);
      if (idx != -1) {
        tickets[idx].assignedTo = helpdeskName;
        tickets[idx].status = 'In Progress';
        tickets[idx].history.add(historyLog);
        tickets[idx].updatedAt = DateTime.now();
        ticketsNotifier.value = [...tickets];

        final notifs = notificationsNotifier.value;
        notificationsNotifier.value = [notif1, notif2, ...notifs];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tiket ditugaskan ke $helpdeskName & status diubah ke In Progress'), backgroundColor: successGreen),
      );
    } else {
      // Rollback
      ticket.assignedTo = oldAssigned;
      ticket.status = oldStatus;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menugaskan tiket ke database Supabase.'), backgroundColor: dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = profileNotifier.value;

    return ValueListenableBuilder<List<Ticket>>(
      valueListenable: ticketsNotifier,
      builder: (context, tickets, _) {
        final ticketIdx = tickets.indexWhere((t) => t.id == widget.ticketId);
        if (ticketIdx == -1) {
          return const Scaffold(body: Center(child: Text('Tiket tidak ditemukan.')));
        }
        final ticket = tickets[ticketIdx];

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              title: Text('Tiket ${ticket.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              bottom: const TabBar(
                labelColor: primaryBlue,
                indicatorColor: primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Detail'),
                  Tab(text: 'Komentar'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildDetailTab(context, ticket, currentUser),
                _buildCommentTab(context, ticket, currentUser),
                _buildHistoryTab(context, ticket),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 1: DETAIL TIKET ---
  Widget _buildDetailTab(BuildContext context, Ticket ticket, UserProfile currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdmin = currentUser.role == 'Admin';
    final bool isHelpdesk = currentUser.role == 'Helpdesk';

    // Ambil daftar petugas helpdesk dari database user
    final helpdesks = usersNotifier.value.where((u) => u.role == 'Helpdesk').map((u) => u.name).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(ticket.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CustomBadge(text: ticket.status, color: getStatusColor(ticket.status)),
            const SizedBox(width: 8),
            CustomBadge(text: ticket.priority, color: getPriorityColor(ticket.priority)),
            const SizedBox(width: 8),
            CustomBadge(text: ticket.category, color: Colors.purple.shade400),
          ],
        ),
        const SizedBox(height: 20),

        // Info Metadata Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildMetaRow(Icons.person_outline, 'Pelapor', ticket.createdBy),
              const Divider(height: 20),
              _buildMetaRow(Icons.support_agent_rounded, 'Petugas', ticket.assignedTo ?? 'Belum Ditugaskan'),
              const Divider(height: 20),
              _buildMetaRow(Icons.calendar_today_rounded, 'Dibuat', _formatDateTime(ticket.createdAt)),
              const Divider(height: 20),
              _buildMetaRow(Icons.update_rounded, 'Diperbarui', _formatDateTime(ticket.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Deskripsi Laporan
        const Text('Deskripsi Masalah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          ticket.description,
          style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.grey.shade300 : Colors.black87),
        ),
        const SizedBox(height: 24),

        // Lampiran Gambar
        const Text('Lampiran Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (ticket.attachmentName != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: primaryBlue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.attachmentName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Lampiran gambar keluhan', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, color: primaryBlue),
                  onPressed: () {
                    // Tampilkan simulasi popup image viewer
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(ticket.attachmentName!, style: const TextStyle(fontSize: 14)),
                        content: Container(
                          width: double.maxFinite,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? cardDark.withOpacity(0.4) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Tidak ada lampiran gambar.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),

        const SizedBox(height: 32),

        // --- AKSI PENGGUNA BERDASARKAN ROLE ---

        // 1. HELP DESK ACTIONS (Selesaikan Tiket)
        if (isHelpdesk && ticket.assignedTo == currentUser.name) ...[
          if (ticket.status == 'In Progress' || ticket.status == 'on progress') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('SELESAI / FINISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () => _changeStatus(ticket, 'Closed'),
              ),
            ),
          ] else if (ticket.status == 'Closed' || ticket.status == 'Close') ...[
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, color: successGreen, size: 20),
                  SizedBox(width: 8),
                  Text('Pekerjaan Selesai & Tiket Ditutup', style: TextStyle(fontWeight: FontWeight.bold, color: successGreen)),
                ],
              ),
            ),
          ]
        ],

        // 2. ADMIN ACTIONS (Assign Helpdesk & Change Status automatically)
        if (isAdmin) ...[
          const Text('Aksi Administrasi (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? cardDark.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ticket.status == 'Open') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('TERIMA TIKET (ASSIGN)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _changeStatus(ticket, 'Assign'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (ticket.status == 'Open' || ticket.status == 'Assign') ...[
                  const Text('Tugaskan Tiket Kepada:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: helpdesks.contains(ticket.assignedTo) ? ticket.assignedTo : null,
                    hint: const Text('Pilih Petugas Helpdesk'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: helpdesks.map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _assignHelpdesk(ticket, v);
                    },
                  ),
                ] else ...[
                  Text(
                    'Tiket sedang diproses oleh: ${ticket.assignedTo ?? "-"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                  ),
                ],
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: slateGray, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: slateGray, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $timeStr';
  }

  // --- TAB 2: CHAT KOMENTAR ---
  Widget _buildCommentTab(BuildContext context, Ticket ticket, UserProfile currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Daftar Komentar
        Expanded(
          child: ticket.comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey, size: 48),
                      SizedBox(height: 12),
                      Text('Belum ada komentar.', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Tulis komentar pertama untuk diskusi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.comments.length,
                  itemBuilder: (context, index) {
                    final comment = ticket.comments[index];
                    final bool isMe = comment.userName == currentUser.name;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? primaryBlue
                              : (isDark ? cardDark : Colors.grey.shade100),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                '${comment.userName} (${comment.userRole})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isDark ? primaryBlue : darkNavy,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatTimeOnly(comment.createdAt),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Text input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? bgDark : Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis tanggapan atau solusi...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: isDark ? cardDark : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryBlue,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _addComment(ticket),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOnly(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // --- TAB 3: TIMELINE RIWAYAT ---
  Widget _buildHistoryTab(BuildContext context, Ticket ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Urutkan riwayat paling baru di atas
    final reversedHistory = List<HistoryLog>.from(ticket.history)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (reversedHistory.isEmpty) {
      return const Center(child: Text('Belum ada riwayat aktivitas.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reversedHistory.length,
      itemBuilder: (context, index) {
        final log = reversedHistory[index];
        final bool isLast = index == reversedHistory.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Timeline indicators
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Log details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.action,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Oleh: ${log.performedBy}',
                    style: TextStyle(color: isDark ? slateGray : Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(log.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}

// -- SCREEN: NOTIFICATION (LIVE NOTIFICATION CLICKS) --
