import 'package:flutter/material.dart';

import '../data/models/user.dart';

class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final bool showOnlineIndicator;
  final VoidCallback? onTap;

  const UserAvatar({super.key, this.user, this.size = 40, this.showOnlineIndicator = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: _getUserColor(user?.id ?? '', colorScheme),
              backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty ? NetworkImage(user!.avatar!) : null,
              child:
                  user?.avatar == null || user!.avatar!.isEmpty
                      ? Text(
                        _getInitials(user?.name ?? '?'),
                        style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
                      )
                      : null,
            ),
          ),

          // Online indicator
          if (showOnlineIndicator && user?.isOnline == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  Color _getUserColor(String userId, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.purple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
