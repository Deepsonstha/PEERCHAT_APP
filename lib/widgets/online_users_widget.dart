import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/user.dart';
import '../screens/all_users_screen.dart';

class OnlineUsersWidget extends StatelessWidget {
  final List<User> onlineUsers;
  final User? currentUser;

  const OnlineUsersWidget({super.key, required this.onlineUsers, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (onlineUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 32, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text('No users online', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(
                'Start P2P chat to connect with others',
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user count and view all button
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 8.0),
            child: Row(
              children: [
                Icon(Icons.wifi, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Connected Users (${onlineUsers.length})',
                  style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAllUsers(context),
                  icon: Icon(Icons.people, size: 16, color: colorScheme.primary),
                  label: Text('View All', style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Users list
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: onlineUsers.length,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                final isCurrentUser = currentUser?.id == user.id;

                return Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: _buildUserAvatar(context, user, isCurrentUser));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, User user, bool isCurrentUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showUserDetails(context, user),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isCurrentUser ? Border.all(color: colorScheme.primary, width: 2) : null,
                  boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: CircleAvatar(
                  radius: isCurrentUser ? 22 : 24,
                  backgroundColor: isCurrentUser ? colorScheme.primary : _getUserColor(user.id, colorScheme),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: isCurrentUser ? colorScheme.onPrimary : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Online indicator
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 52,
            child: Text(
              isCurrentUser ? 'You' : user.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isCurrentUser ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserColor(String userId, ColorScheme colorScheme) {
    final colors = [colorScheme.secondary, colorScheme.tertiary, Colors.purple, Colors.indigo, Colors.teal, Colors.orange, Colors.pink, Colors.cyan];

    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  void _showAllUsers(BuildContext context) {
    Get.to(() => AllUsersScreen(users: onlineUsers, currentUser: currentUser));
  }

  void _showUserDetails(BuildContext context, User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentUser = currentUser?.id == user.id;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isCurrentUser ? colorScheme.primary : _getUserColor(user.id, colorScheme),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: isCurrentUser ? colorScheme.onPrimary : Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleMedium),
                      if (isCurrentUser)
                        Text('You', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, Icons.person, 'User ID', user.id),
                const SizedBox(height: 8),
                _buildInfoRow(context, Icons.access_time, 'Last Seen', _formatLastSeen(user.lastSeen)),
                const SizedBox(height: 8),
                _buildInfoRow(context, Icons.circle, 'Status', 'Online', valueColor: Colors.green),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: theme.textTheme.bodySmall?.copyWith(color: valueColor ?? colorScheme.onSurface), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
