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
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAttachment(String source) async {
    try {
      setState(() {
        _isUploading = true;
      });
      final XFile? image = await _picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _simulatedAttachmentName = image.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lampiran berhasil ditambahkan: ${image.name}'), backgroundColor: successGreen),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih lampiran: $e'), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
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
                  _pickAttachment('camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: primaryBlue),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  context.pop();
                  _pickAttachment('gallery');
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
