import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -- MODELS --
class UserProfile {
  String id;
  String name;
  String email;
  String role; // 'User', 'Helpdesk', 'Admin'
  String password;
  bool isActive;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
    this.isActive = true,
  });

  UserProfile copyWith({String? name, String? email, String? role, String? password, bool? isActive}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      password: json['password'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'password': password,
      'is_active': isActive,
    };
  }
}

class Comment {
  final String id;
  final String userName;
  final String userRole;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      userRole: json['user_role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_role': userRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class HistoryLog {
  final String id;
  final String action;
  final String performedBy;
  final DateTime createdAt;

  HistoryLog({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.createdAt,
  });

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      id: json['id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'performed_by': performedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final String category; // 'Hardware', 'Software', 'Network'
  final String priority; // 'Low', 'Medium', 'High'
  String status; // 'Open', 'In Progress', 'Resolved', 'Closed'
  final String createdBy;
  String? assignedTo; // Nama helpdesk yang ditugaskan
  final DateTime createdAt;
  DateTime updatedAt;
  String? attachmentName;
  final List<Comment> comments;
  final List<HistoryLog> history;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentName,
    required this.comments,
    required this.history,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    var commentsList = json['comments'] as List? ?? [];
    var historyList = json['history'] as List? ?? [];

    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachmentName: json['attachment_name'] as String?,
      comments: commentsList.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList(),
      history: historyList.map((h) => HistoryLog.fromJson(h as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachment_name': attachmentName,
    };
  }
}

class NotificationItem {
  final String id;
  final String ticketId;
  final String title;
  final String description;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.description,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'title': title,
      'description': description,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

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

// -- GLOBAL STATES / MOCK DATABASE --
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Sesi Login Pengguna saat ini
final ValueNotifier<UserProfile> profileNotifier = ValueNotifier(UserProfile(
  id: 'U-1',
  name: 'Alfin',
  email: 'user@example.com',
  role: 'User',
  password: 'user123',
  isActive: true,
));

// Database Pengguna
final ValueNotifier<List<UserProfile>> usersNotifier = ValueNotifier([
  UserProfile(id: 'U-1', name: 'Alfin', email: 'user@example.com', role: 'User', password: 'user123'),
  UserProfile(id: 'U-2', name: 'Budi Helpdesk', email: 'helpdesk@example.com', role: 'Helpdesk', password: 'helpdesk123'),
  UserProfile(id: 'U-3', name: 'Joni Admin', email: 'admin@example.com', role: 'Admin', password: 'admin123'),
  UserProfile(id: 'U-4', name: 'Dewi Rahma', email: 'dewi@example.com', role: 'User', password: 'user123'),
]);

// Database Tiket
final ValueNotifier<List<Ticket>> ticketsNotifier = ValueNotifier([
  Ticket(
    id: 'T-001',
    title: 'Komputer tidak bisa menyala',
    description: 'Komputer di ruang staff mati total setelah pemadaman listrik kemarin. Sudah mencoba menekan tombol power berulang kali tetapi tidak ada respon.',
    category: 'Hardware',
    priority: 'High',
    status: 'In Progress',
    createdBy: 'Alfin',
    assignedTo: 'Budi Helpdesk',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    comments: [
      Comment(id: 'C-1', userName: 'Alfin', userRole: 'User', content: 'Komputer mati total, lampu indikator power juga mati.', createdAt: DateTime.now().subtract(const Duration(days: 3))),
      Comment(id: 'C-2', userName: 'Budi Helpdesk', userRole: 'Helpdesk', content: 'Baik, saya akan membawa power supply cadangan ke lokasi untuk pengetesan.', createdAt: DateTime.now().subtract(const Duration(days: 2))),
    ],
    history: [
      HistoryLog(id: 'H-1', action: 'Tiket dibuat', performedBy: 'Alfin', createdAt: DateTime.now().subtract(const Duration(days: 3))),
      HistoryLog(id: 'H-2', action: 'Tiket ditugaskan ke Budi Helpdesk', performedBy: 'System', createdAt: DateTime.now().subtract(const Duration(days: 3))),
      HistoryLog(id: 'H-3', action: 'Status diubah ke In Progress', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 2))),
    ],
  ),
  Ticket(
    id: 'T-002',
    title: 'Tidak bisa akses email kantor',
    description: 'Saat mencoba login ke Outlook muncul pesan kesalahan autentikasi terus menerus, padahal password yang digunakan sudah benar.',
    category: 'Software',
    priority: 'Medium',
    status: 'Open',
    createdBy: 'Alfin',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    comments: [],
    history: [
      HistoryLog(id: 'H-4', action: 'Tiket dibuat', performedBy: 'Alfin', createdAt: DateTime.now().subtract(const Duration(days: 1))),
    ],
  ),
  Ticket(
    id: 'T-003',
    title: 'Printer lantai 2 error',
    description: 'Muncul tulisan paper jam pada layar printer lantai 2 sebelah kanan, meskipun kertas yang menyangkut sudah dibersihkan.',
    category: 'Hardware',
    priority: 'Low',
    status: 'Resolved',
    createdBy: 'Alfin',
    assignedTo: 'Budi Helpdesk',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 9)),
    comments: [
      Comment(id: 'C-3', userName: 'Budi Helpdesk', userRole: 'Helpdesk', content: 'Sensor kertas printer sudah dibersihkan dan berfungsi kembali normal.', createdAt: DateTime.now().subtract(const Duration(days: 9))),
    ],
    history: [
      HistoryLog(id: 'H-5', action: 'Tiket dibuat', performedBy: 'Alfin', createdAt: DateTime.now().subtract(const Duration(days: 10))),
      HistoryLog(id: 'H-6', action: 'Tiket ditugaskan ke Budi Helpdesk', performedBy: 'System', createdAt: DateTime.now().subtract(const Duration(days: 10))),
      HistoryLog(id: 'H-7', action: 'Status diubah ke In Progress', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 9))),
      HistoryLog(id: 'H-8', action: 'Status diubah ke Resolved', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 9))),
    ],
  ),
  Ticket(
    id: 'T-004',
    title: 'Koneksi internet lambat di ruang meeting',
    description: 'Koneksi internet Wi-Fi di ruang meeting utama lambat dan sering terputus-putus saat video conference.',
    category: 'Network',
    priority: 'High',
    status: 'Open',
    createdBy: 'Dewi Rahma',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    comments: [],
    history: [
      HistoryLog(id: 'H-9', action: 'Tiket dibuat', performedBy: 'Dewi Rahma', createdAt: DateTime.now().subtract(const Duration(hours: 4))),
    ],
  ),
  Ticket(
    id: 'T-005',
    title: 'Request install software Figma',
    description: 'Memerlukan instalasi aplikasi Figma Desktop untuk pengerjaan proyek UI/UX desain tim marketing.',
    category: 'Software',
    priority: 'Low',
    status: 'Closed',
    createdBy: 'Budi Helpdesk',
    assignedTo: 'Budi Helpdesk',
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    updatedAt: DateTime.now().subtract(const Duration(days: 14)),
    comments: [],
    history: [
      HistoryLog(id: 'H-10', action: 'Tiket dibuat', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 15))),
      HistoryLog(id: 'H-11', action: 'Status diubah ke Resolved', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 14))),
      HistoryLog(id: 'H-12', action: 'Status diubah ke Closed', performedBy: 'Budi Helpdesk', createdAt: DateTime.now().subtract(const Duration(days: 14))),
    ],
  ),
]);

// Database Notifikasi
final ValueNotifier<List<NotificationItem>> notificationsNotifier = ValueNotifier([
  NotificationItem(id: 'N-1', ticketId: 'T-001', title: 'Tiket T-001 Diperbarui', description: 'Status tiket "Komputer tidak bisa menyala" berubah menjadi In Progress.', isRead: false, createdAt: DateTime.now().subtract(const Duration(days: 2))),
  NotificationItem(id: 'N-2', ticketId: 'T-001', title: 'Komentar Baru di T-001', description: 'Budi Helpdesk menambahkan komentar pada tiket Anda.', isRead: false, createdAt: DateTime.now().subtract(const Duration(days: 2))),
  NotificationItem(id: 'N-3', ticketId: 'T-003', title: 'Tiket T-003 Selesai', description: 'Tiket "Printer lantai 2 error" telah diselesaikan.', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 9))),
  NotificationItem(id: 'N-4', ticketId: 'T-005', title: 'Tiket T-005 Ditutup', description: 'Tiket "Request install software Figma" telah ditutup.', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 14))),
]);

// -- STYLING TOKENS --
const Color primaryBlue = Color(0xFF2563EB);
const Color darkNavy = Color(0xFF1E3A5F);
const Color slateGray = Color(0xFF64748B);
const Color successGreen = Color(0xFF16A34A);
const Color warningOrange = Color(0xFFD97706);
const Color dangerRed = Color(0xFFDC2626);
const Color lightBlueBg = Color(0xFFDBEAFE);
const Color lightGrayBg = Color(0xFFF1F5F9);

const Color bgLight = lightGrayBg;
const Color bgDark = Color(0xFF0F172A); // Modern slate dark bg
const Color cardDark = Color(0xFF1E293B); // Card dark bg

// Ticket Status Colors
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return primaryBlue;
    case 'assign':
    case 'assigned':
      return Colors.purple;
    case 'in progress':
    case 'on progress':
      return warningOrange;
    case 'resolved':
      return successGreen;
    case 'closed':
    case 'close':
      return slateGray;
    default:
      return primaryBlue;
  }
}

// Ticket Priority Colors
Color getPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return dangerRed;
    case 'medium':
      return warningOrange;
    case 'low':
      return successGreen;
    default:
      return slateGray;
  }
}

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
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = _getSelectedIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: profileNotifier,
      builder: (context, user, _) {
        final bool isUser = user.role == 'User';

        return Scaffold(
          body: child,
          floatingActionButton: !isUser
              ? null
              : FloatingActionButton(
                  onPressed: () => context.push('/create-ticket'),
                  backgroundColor: primaryBlue,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
          floatingActionButtonLocation: !isUser ? null : FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: isDark ? cardDark : Colors.white,
            shape: !isUser ? null : const CircularNotchedRectangle(),
            notchMargin: 8,
            elevation: 8,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: !isUser ? MainAxisAlignment.spaceAround : MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(context, icon: Icons.grid_view_rounded, label: 'Dashboard', index: 0, currentIndex: currentIndex, path: '/dashboard'),
                  _buildNavItem(context, icon: Icons.receipt_long_rounded, label: 'Tiket', index: 1, currentIndex: currentIndex, path: '/tickets'),
                  if (isUser) const SizedBox(width: 48), // Space for FAB
                  _buildNavItem(context, icon: Icons.notifications_none_rounded, label: 'Notifikasi', index: 2, currentIndex: currentIndex, path: '/notifications'),
                  _buildNavItem(context, icon: Icons.person_outline_rounded, label: 'Profil', index: 3, currentIndex: currentIndex, path: '/profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _getSelectedIndex(String location) {
    if (location.contains('/dashboard')) return 0;
    if (location.contains('/tickets')) return 1;
    if (location.contains('/notifications')) return 2;
    if (location.contains('/profile')) return 3;
    return 0;
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, required int currentIndex, required String path}) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? primaryBlue : (isDark ? slateGray : Colors.grey.shade500);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(path),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- GENERAL UI COMPONENTS --
class CustomBadge extends StatelessWidget {
  final String text;
  final Color color;
  const CustomBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// -- SCREEN: SPLASH --
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, darkNavy],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: const Center(
                  child: Text(
                    'E',
                    style: TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'E-Ticketing',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                'Helpdesk Mobile App',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, letterSpacing: 0.5),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- SCREEN: LOGIN --
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
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'Semua';
  String _categoryFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = profileNotifier.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tiket Keluhan')),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket berdasarkan ID atau judul...',
                    filled: true,
                    fillColor: isDark ? cardDark : Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Row (Horizontal List)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Open', 'In Progress', 'Resolved', 'Closed'].map((status) {
                      final isSelected = _statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _statusFilter = status);
                          },
                          selectedColor: primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Category Filter Row
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Hardware', 'Software', 'Network'].map((cat) {
                      final isSelected = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _categoryFilter = cat);
                          },
                          selectedColor: Colors.purple.shade400,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tiket List view
          Expanded(
            child: ValueListenableBuilder<List<Ticket>>(
              valueListenable: ticketsNotifier,
              builder: (context, allTickets, _) {
                // Filter tickets by user role
                var filtered = currentUser.role == 'User'
                    ? allTickets.where((t) => t.createdBy == currentUser.name).toList()
                    : currentUser.role == 'Helpdesk'
                        ? allTickets.where((t) => t.assignedTo == currentUser.name).toList()
                        : allTickets;

                // Filter status
                if (_statusFilter != 'Semua') {
                  filtered = filtered.where((t) => t.status.toLowerCase() == _statusFilter.toLowerCase()).toList();
                }

                // Filter category
                if (_categoryFilter != 'Semua') {
                  filtered = filtered.where((t) => t.category.toLowerCase() == _categoryFilter.toLowerCase()).toList();
                }

                // Filter search
                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.trim().toLowerCase();
                  filtered = filtered.where((t) => t.title.toLowerCase().contains(q) || t.id.toLowerCase().contains(q)).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada tiket yang cocok.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    return _buildFullTicketCard(context, ticket);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFullTicketCard(BuildContext context, Ticket ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/ticket/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomBadge(text: ticket.status, color: getStatusColor(ticket.status)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(ticket.id, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('•', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text('Dibuat oleh: ${ticket.createdBy}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomBadge(text: ticket.category, color: Colors.purple.shade300),
                      const SizedBox(width: 8),
                      CustomBadge(text: ticket.priority, color: getPriorityColor(ticket.priority)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(ticket.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

// -- SCREEN: CREATE TICKET --
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Hardware';
  String _selectedPriority = 'Medium';
  String? _simulatedAttachmentName;
  bool _isUploading = false;

  void _simulatedPickAttachment(String source) {
    setState(() {
      _isUploading = true;
    });

    // Simulate 1 second upload duration
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _simulatedAttachmentName = source == 'camera' ? 'CAM_FOTO_${DateTime.now().millisecond}.JPG' : 'GALLERY_LAMPIRAN_${DateTime.now().millisecond}.PNG';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lampiran berhasil ditambahkan ($source)'), backgroundColor: successGreen),
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tambah Lampiran Gambar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: primaryBlue),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  context.pop();
                  _simulatedPickAttachment('camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: primaryBlue),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  context.pop();
                  _simulatedPickAttachment('gallery');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final allTickets = ticketsNotifier.value;
    final newId = 'T-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'; // generate a short unique ID
    final user = profileNotifier.value;

    final initialHistory = HistoryLog(
      id: 'H-${DateTime.now().millisecondsSinceEpoch}',
      action: 'Tiket berhasil dibuat',
      performedBy: user.name,
      createdAt: DateTime.now(),
    );

    final newTicket = Ticket(
      id: newId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      status: 'Open',
      createdBy: user.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachmentName: _simulatedAttachmentName,
      comments: [],
      history: [initialHistory],
    );

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Simpan ke MySQL
    final successTicket = await ApiService.createTicket(newTicket);
    final successHistory = await ApiService.addHistory(newId, initialHistory);

    // Simulasikan notifikasi baru untuk helpdesk & admin
    final notifId = 'N-${DateTime.now().millisecondsSinceEpoch}';
    final notifItem = NotificationItem(
      id: notifId,
      ticketId: newId,
      title: 'Tiket Baru $newId',
      description: 'Tiket "${newTicket.title}" baru saja dilaporkan oleh ${newTicket.createdBy}.',
      isRead: false,
      createdAt: DateTime.now(),
    );
    await ApiService.addNotification(notifItem);

    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    if (successTicket && successHistory) {
      // Add to Database
      ticketsNotifier.value = [...allTickets, newTicket];

      final notifs = notificationsNotifier.value;
      notificationsNotifier.value = [notifItem, ...notifs];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket Keluhan berhasil dibuat!'), backgroundColor: successGreen),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan tiket ke database Supabase.'), backgroundColor: dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text('Judul Masalah', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong' : null,
              decoration: _inputDec(isDark, 'Contoh: Printer rusak / WiFi error'),
            ),
            const SizedBox(height: 16),

            const Text('Deskripsi Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi tidak boleh kosong' : null,
              decoration: _inputDec(isDark, 'Jelaskan kronologi & detail masalah...'),
            ),
            const SizedBox(height: 16),

            const Text('Kategori Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _inputDec(isDark, ''),
              value: _selectedCategory,
              items: ['Hardware', 'Software', 'Network']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'Hardware'),
            ),
            const SizedBox(height: 16),

            const Text('Tingkat Prioritas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityBtn('Low', Colors.green, _selectedPriority == 'Low'),
                const SizedBox(width: 12),
                _buildPriorityBtn('Medium', Colors.orange, _selectedPriority == 'Medium'),
                const SizedBox(width: 12),
                _buildPriorityBtn('High', Colors.red, _selectedPriority == 'High'),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Lampiran Foto Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploading ? null : _showAttachmentOptions,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.4), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? cardDark : Colors.grey.shade50,
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : _simulatedAttachmentName != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, color: successGreen, size: 32),
                              const SizedBox(height: 6),
                              Text(
                                _simulatedAttachmentName!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: successGreen),
                              ),
                              const SizedBox(height: 4),
                              Text('Ketuk untuk mengganti lampiran', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined, color: primaryBlue, size: 36),
                              SizedBox(height: 6),
                              Text('Tambah Lampiran Gambar', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 4),
                              Text('Bisa menggunakan Kamera atau Galeri ponsel', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 36),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitTicket,
                child: const Text('Kirim Tiket Keluhan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? cardDark : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
      ),
    );
  }

  Widget _buildPriorityBtn(String text, Color color, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? color.withOpacity(0.2) : color.withOpacity(0.1)) : (isDark ? cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? color : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// -- SCREEN: TICKET DETAIL (DETAIL, CHAT/COMMENT, TIMELINE HISTORY) --
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
