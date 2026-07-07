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
