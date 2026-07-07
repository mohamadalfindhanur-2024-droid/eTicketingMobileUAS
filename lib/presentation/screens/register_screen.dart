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
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedRole = 'User';
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final users = usersNotifier.value;
    final email = _emailController.text.trim().toLowerCase();

    // Check if email already registered
    if (users.any((u) => u.email.toLowerCase() == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sudah terdaftar!'),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }

    // Add new user
    final newUser = UserProfile(
      id: 'U-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      email: email,
      role: _selectedRole,
      password: _passwordController.text,
    );

    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Simpan ke MySQL
    final success = await ApiService.register(newUser);
    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    if (success) {
      usersNotifier.value = [...users, newUser];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi Berhasil! Silakan masuk.'),
          backgroundColor: successGreen,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftar ke server MySQL. Pastikan database menyala!'),
          backgroundColor: dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: isDark ? bgDark : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                          decoration: _inputDec(isDark, 'Masukkan nama lengkap', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                          decoration: _inputDec(isDark, 'contoh@perusahaan.com', Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),
                        const Text('Peran Aplikasi (Role)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          items: ['User', 'Helpdesk', 'Admin']
                              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRole = v ?? 'User'),
                          decoration: _inputDec(isDark, '', Icons.supervised_user_circle_outlined),
                        ),
                        const SizedBox(height: 16),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText1,
                          validator: (v) => (v == null || v.length < 5) ? 'Minimal 5 karakter' : null,
                          decoration: InputDecoration(
                            hintText: 'Buat password',
                            filled: true,
                            fillColor: isDark ? cardDark : Colors.grey.shade100,
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _obscureText1 = !_obscureText1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Konfirmasi Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureText2,
                          validator: (v) {
                            if (v != _passwordController.text) return 'Password tidak cocok';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Ulangi password',
                            filled: true,
                            fillColor: isDark ? cardDark : Colors.grey.shade100,
                            prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _obscureText2 = !_obscureText2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _register,
                            child: const Text('Daftar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(bool isDark, String hint, IconData prefix) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? cardDark : Colors.grey.shade100,
      prefixIcon: Icon(prefix, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

// -- SCREEN: FORGOT PASSWORD --
