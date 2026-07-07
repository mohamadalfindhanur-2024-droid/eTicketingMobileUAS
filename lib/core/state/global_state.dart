import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/ticket.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/comment.dart';
import '../../data/models/history_log.dart';


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

