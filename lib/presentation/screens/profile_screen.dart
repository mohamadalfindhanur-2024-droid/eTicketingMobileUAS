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
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, UserProfile user, bool isDark) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Edit Profil Pengguna'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? cardDark : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? cardDark : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Perbarui di database
                  final users = usersNotifier.value;
                  final idx = users.indexWhere((u) => u.id == user.id);
                  if (idx != -1) {
                    final updatedUser = user.copyWith(name: nameController.text.trim(), email: emailController.text.trim());
                    users[idx] = updatedUser;
                    usersNotifier.value = [...users];
                    profileNotifier.value = updatedUser; // Update session
                  }
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: successGreen),
                  );
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: profileNotifier,
        builder: (context, user, _) {
          return ValueListenableBuilder<List<Ticket>>(
            valueListenable: ticketsNotifier,
            builder: (context, allTickets, _) {
              // Hitung statistik tiket khusus user ini
              final userTickets = user.role == 'User'
                  ? allTickets.where((t) => t.createdBy == user.name).toList()
                  : user.role == 'Helpdesk'
                      ? allTickets.where((t) => t.assignedTo == user.name).toList()
                      : allTickets;

              final total = userTickets.length;
              final open = userTickets.where((t) => t.status == 'Open').length;
              final completed = userTickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark ? primaryBlue.withOpacity(0.2) : primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryBlue.withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: primaryBlue, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(user.email, style: TextStyle(color: isDark ? slateGray : Colors.grey, fontSize: 13)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statistik Mini Row
                  Row(
                    children: [
                      Expanded(child: _buildProfileStat(context, '$total', 'Tiket')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileStat(context, '$open', 'Open')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileStat(context, '$completed', 'Selesai')),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        // Edit profile option
                        ListTile(
                          leading: const Icon(Icons.badge_outlined, color: primaryBlue),
                          title: const Text('Edit Informasi Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => _showEditProfileDialog(context, user, isDark),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.15)),

                        // Dark Mode Toggle
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (_, mode, __) => ListTile(
                            leading: const Icon(Icons.dark_mode_outlined, color: primaryBlue),
                            title: const Text('Mode Gelap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            trailing: Switch(
                              activeColor: Colors.white,
                              activeTrackColor: primaryBlue,
                              value: mode == ThemeMode.dark,
                              onChanged: (val) {
                                themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                              },
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.15)),

                        // Notifications Link
                        ListTile(
                          leading: const Icon(Icons.notifications_none_outlined, color: primaryBlue),
                          title: const Text('Daftar Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => context.push('/notifications'),
                        ),

                        // ADMIN SPECIAL: User Management Link
                        if (user.role == 'Admin') ...[
                          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                          ListTile(
                            leading: const Icon(Icons.manage_accounts_outlined, color: primaryBlue),
                            title: const Text('Kelola Akun Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Nonaktifkan atau rubah role user', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => context.push('/user-management'),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // LOGOUT BUTTON
                  InkWell(
                    onTap: () {
                      context.go('/login');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Berhasil keluar dari akun'), backgroundColor: successGreen),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Keluar Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileStat(BuildContext context, String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// -- SCREEN: USER MANAGEMENT (ADMIN ONLY, BR-002: NONAKTIFKAN PENGGUNA) --
