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
