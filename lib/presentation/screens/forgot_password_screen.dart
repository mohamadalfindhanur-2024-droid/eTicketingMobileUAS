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
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  int _step = 1; // 1: Email, 2: OTP, 3: Reset Password

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final users = usersNotifier.value;
    if (!users.any((u) => u.email.toLowerCase() == _emailController.text.trim().toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak ditemukan dalam sistem!'), backgroundColor: dangerRed),
      );
      return;
    }
    setState(() => _step = 2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP Terkirim! Gunakan kode: 12345'), backgroundColor: successGreen),
    );
  }

  void _verifyOtp() {
    if (_otpController.text == '12345') {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP salah! Gunakan 12345'), backgroundColor: dangerRed),
      );
    }
  }

  void _resetPassword() {
    if (_newPasswordController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 5 karakter!'), backgroundColor: dangerRed),
      );
      return;
    }

    final users = usersNotifier.value;
    final email = _emailController.text.trim().toLowerCase();
    final userIdx = users.indexWhere((u) => u.email.toLowerCase() == email);

    if (userIdx != -1) {
      users[userIdx].password = _newPasswordController.text;
      usersNotifier.value = [...users];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil dirubah! Silakan login.'), backgroundColor: successGreen),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('Lupa Password', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        if (_step == 1) ...[
                          const Text('Verifikasi Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Masukkan email terdaftar Anda untuk menerima kode OTP verifikasi.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 24),
                          const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            validator: (v) => (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
                            decoration: InputDecoration(
                              hintText: 'contoh@email.com',
                              filled: true,
                              fillColor: isDark ? cardDark : Colors.grey.shade100,
                              prefixIcon: const Icon(Icons.email, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                              onPressed: _sendOtp,
                              child: const Text('Kirim OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else if (_step == 2) ...[
                          const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Kode OTP telah dikirim ke ${_emailController.text}. Masukkan kode tersebut di bawah.', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 24),
                          const Text('Kode OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8),
                            decoration: InputDecoration(
                              hintText: 'XXXXX',
                              hintStyle: const TextStyle(letterSpacing: 0),
                              filled: true,
                              fillColor: isDark ? cardDark : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                              onPressed: _verifyOtp,
                              child: const Text('Verifikasi OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else if (_step == 3) ...[
                          const Text('Buat Password Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Password baru Anda harus minimal 5 karakter.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 24),
                          const Text('Password Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Ketik password baru',
                              filled: true,
                              fillColor: isDark ? cardDark : Colors.grey.shade100,
                              prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                              onPressed: _resetPassword,
                              child: const Text('Simpan Password Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -- SCREEN: DASHBOARD --
