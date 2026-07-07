import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/state/global_state.dart';
import 'services/api_service.dart';
import 'data/models/user_profile.dart';
import 'data/models/ticket.dart';
import 'data/models/notification_item.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/ticket_list_screen.dart';
import 'presentation/screens/create_ticket_screen.dart';
import 'presentation/screens/ticket_detail_screen.dart';
import 'presentation/screens/notification_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/user_management_screen.dart';
import 'presentation/screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inisialisasi Supabase
    await Supabase.initialize(
      url: 'https://ocluzdvglyjaregakooc.supabase.co',
      anonKey: 'sb_publishable_4xAnBDHIca3_n-nAa3x34Q_ymQyWzmD',
    );
    debugPrint('Supabase Cloud berhasil diinisialisasi.');
  } catch (e) {
    debugPrint('Gagal inisialisasi Supabase: $e');
  }

  // Lakukan sinkronisasi data dari database Supabase
  await _initDatabase();

  runApp(const HelpdeskApp());
}

Future<void> _initDatabase() async {
  try {
    final data = await ApiService.syncData();
    if (data != null && data['status'] == 'success') {
      // Muat users
      if (data['users'] != null && (data['users'] as List).isNotEmpty) {
        final List<dynamic> usersJson = data['users'];
        usersNotifier.value = usersJson.map((u) => UserProfile.fromJson(u)).toList();
      } else {
        // Seeding default users ke Supabase jika kosong
        debugPrint('Tabel users di Supabase kosong. Melakukan seeding...');
        final defaultUsers = [
          UserProfile(id: 'U-1', name: 'Alfin', email: 'user@example.com', role: 'User', password: 'user123'),
          UserProfile(id: 'U-2', name: 'Budi Helpdesk', email: 'helpdesk@example.com', role: 'Helpdesk', password: 'helpdesk123'),
          UserProfile(id: 'U-3', name: 'Joni Admin', email: 'admin@example.com', role: 'Admin', password: 'admin123'),
        ];
        for (var u in defaultUsers) {
          await ApiService.register(u);
        }
        usersNotifier.value = defaultUsers;
      }
      
      // Muat tickets
      if (data['tickets'] != null) {
        final List<dynamic> ticketsJson = data['tickets'];
        ticketsNotifier.value = ticketsJson.map((t) => Ticket.fromJson(t)).toList();
      }
      
      // Muat notifications
      if (data['notifications'] != null) {
        final List<dynamic> notifsJson = data['notifications'];
        notificationsNotifier.value = notifsJson.map((n) => NotificationItem.fromJson(n)).toList();
      }
      debugPrint('Database Supabase berhasil disinkronisasi.');
    } else {
      debugPrint('Gagal menyelaraskan database Supabase. Menggunakan backup lokal.');
    }
  } catch (e) {
    debugPrint('Gagal koneksi ke Supabase: $e. Menggunakan backup lokal.');
  }
}


class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp.router(
          title: 'E-Ticketing Helpdesk',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: bgLight,
            primaryColor: primaryBlue,
            colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.light),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: bgDark,
            primaryColor: primaryBlue,
            colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            cardTheme: const CardThemeData(
              color: cardDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// -- ROUTING --
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/tickets', builder: (context, state) => const TicketListScreen()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/create-ticket', builder: (context, state) => const CreateTicketScreen()),
    GoRoute(path: '/ticket/:id', builder: (context, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!)),
    GoRoute(path: '/user-management', builder: (context, state) => const UserManagementScreen()),
  ],
);

// -- MAIN SCAFFOLD (PERSISTENT NAVIGATION) --
