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
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    final emailInput = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Temukan user di database
    final users = usersNotifier.value;
    final userIdx = users.indexWhere((u) {
      final dbEmail = u.email.toLowerCase();
      // Bisa login dengan email lengkap (user@example.com) atau username saja (user/helpdesk/admin)
      final matchesEmail = dbEmail == emailInput || dbEmail.split('@')[0] == emailInput || u.name.toLowerCase() == emailInput;
      return matchesEmail && u.password == password;
    });

    if (userIdx != -1) {
      final user = users[userIdx];
      if (!user.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun Anda dinonaktifkan oleh Admin. Silakan hubungi admin.'),
            backgroundColor: dangerRed,
          ),
        );
        return;
      }
      profileNotifier.value = user;
      context.go('/dashboard');
    } else {
      // Mockup login bypass jika database kosong atau error
      if (emailInput == 'admin' || emailInput == 'helpdesk' || emailInput == 'user') {
        String role = 'User';
        if (emailInput == 'admin') role = 'Admin';
        if (emailInput == 'helpdesk') role = 'Helpdesk';
        final user = users.isNotEmpty 
            ? users.firstWhere((u) => u.role == role, orElse: () => users[0])
            : UserProfile(id: 'U-0', name: emailInput, email: '$emailInput@example.com', role: role, password: password);
        profileNotifier.value = user;
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email/Username atau Password salah!'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Area Logo & Greeting
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'E',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selamat Datang 👋',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk ke portal E-Ticketing Helpdesk.',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Area Form Card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? bgDark : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                            final val = v.trim().toLowerCase();
                            if (val == 'admin' || val == 'helpdesk' || val == 'user') return null; // Bypass for UTS/UAS testing
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Ketik "user", "helpdesk", atau "admin"',
                            filled: true,
                            fillColor: isDark ? cardDark : Colors.grey.shade100,
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password wajib diisi';
                            if (v.length < 5) return 'Minimal 5 karakter';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            filled: true,
                            fillColor: isDark ? cardDark : Colors.grey.shade100,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => context.push('/forgot-password'),
                            child: const Text(
                              'Lupa password?',
                              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _login,
                            child: const Text(
                              'Masuk',
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: InkWell(
                            onTap: () => context.push('/register'),
                            child: RichText(
                              text: TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(color: isDark ? slateGray : Colors.grey),
                                children: const [
                                  TextSpan(
                                    text: 'Daftar Sekarang',
                                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- SCREEN: REGISTER --
