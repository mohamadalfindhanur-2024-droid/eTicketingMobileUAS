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
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';

  void _toggleUserActiveStatus(UserProfile user) async {
    // Admin cannot deactivate themselves!
    if (user.id == profileNotifier.value.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak bisa menonaktifkan akun sendiri!'), backgroundColor: dangerRed),
      );
      return;
    }

    final users = usersNotifier.value;
    final idx = users.indexWhere((u) => u.id == user.id);

    if (idx != -1) {
      final oldActive = users[idx].isActive;
      final updatedStatus = !oldActive;

      // Update temp data
      users[idx].isActive = updatedStatus;

      // Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ApiService.updateUser(users[idx]);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (success) {
        usersNotifier.value = [...users];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun ${user.name} berhasil ${updatedStatus ? "diaktifkan" : "dinonaktifkan"}'),
            backgroundColor: successGreen,
          ),
        );
      } else {
        // Rollback
        users[idx].isActive = oldActive;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status user ke MySQL.'), backgroundColor: dangerRed),
        );
      }
    }
  }

  void _changeUserRole(UserProfile user, String newRole) async {
    if (user.id == profileNotifier.value.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak bisa merubah peran sendiri!'), backgroundColor: dangerRed),
      );
      return;
    }

    final users = usersNotifier.value;
    final idx = users.indexWhere((u) => u.id == user.id);

    if (idx != -1) {
      final oldRole = users[idx].role;
      users[idx].role = newRole;

      // Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ApiService.updateUser(users[idx]);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (success) {
        usersNotifier.value = [...users];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peran ${user.name} berhasil diubah menjadi $newRole'),
            backgroundColor: successGreen,
          ),
        );
      } else {
        // Rollback
        users[idx].role = oldRole;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui role user ke MySQL.'), backgroundColor: dangerRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun Pengguna'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari pengguna berdasarkan nama/email...',
                filled: true,
                fillColor: isDark ? cardDark : Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<UserProfile>>(
              valueListenable: usersNotifier,
              builder: (context, users, _) {
                var list = users;
                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.trim().toLowerCase();
                  list = list.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final user = list[idx];
                    final bool isSelf = user.id == profileNotifier.value.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: user.isActive ? primaryBlue : Colors.grey,
                              radius: 20,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name + (isSelf ? ' (Saya)' : ''),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Role Selection Dropdown (Only for other users)
                                      if (isSelf)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
                                          child: Text(user.role, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                        )
                                      else
                                        Container(
                                          height: 24,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: user.role,
                                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white : Colors.black87),
                                              items: ['User', 'Helpdesk', 'Admin'].map((role) {
                                                return DropdownMenuItem(value: role, child: Text(role));
                                              }).toList(),
                                              onChanged: (v) {
                                                if (v != null) _changeUserRole(user, v);
                                              },
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 12),

                                      // Active/Inactive Badge status
                                      CustomBadge(
                                        text: user.isActive ? 'Aktif' : 'Nonaktif',
                                        color: user.isActive ? successGreen : dangerRed,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Switch to activate/deactivate (Only for other users)
                            if (!isSelf)
                              IconButton(
                                icon: Icon(
                                  user.isActive ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                  color: user.isActive ? successGreen : dangerRed,
                                ),
                                onPressed: () => _toggleUserActiveStatus(user),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
