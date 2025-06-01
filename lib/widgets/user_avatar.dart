import 'dart:developer';

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
              backgroundImage: _isNetworkImage(user?.avatar) ? NetworkImage(user!.avatar!) : null,
              child: _getAvatarChild(),
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

  Widget? _getAvatarChild() {
    final avatar = user?.avatar;

    // Debug logging
    log('UserAvatar: Processing avatar = "$avatar" for user ${user?.name}');

    if (avatar == null || avatar.isEmpty) {
      // Show initials when no avatar
      log('UserAvatar: No avatar, showing initials');
      return Text(_getInitials(user?.name ?? '?'), style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold));
    }

    if (_isEmoji(avatar)) {
      // Show emoji avatar
      log('UserAvatar: Detected emoji avatar: "$avatar"');
      return Text(avatar, style: TextStyle(fontSize: size * 0.6));
    }

    if (_isNetworkImage(avatar)) {
      // Network image will be shown via backgroundImage
      log('UserAvatar: Detected network image: "$avatar"');
      return null;
    }

    // Fallback to initials if avatar format is unknown
    log('UserAvatar: Unknown avatar format, showing initials');
    return Text(_getInitials(user?.name ?? '?'), style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold));
  }

  bool _isEmoji(String? text) {
    if (text == null || text.isEmpty) return false;

    log('UserAvatar: Checking if "$text" is emoji');

    // First, check for common emoji patterns
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|' // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|' // Misc Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|' // Transport and Map Symbols
      r'[\u{1F1E0}-\u{1F1FF}]|' // Regional Indicator Symbols
      r'[\u{2600}-\u{26FF}]|' // Misc symbols
      r'[\u{2700}-\u{27BF}]|' // Dingbats
      r'[\u{1F900}-\u{1F9FF}]|' // Supplemental Symbols and Pictographs
      r'[\u{1F018}-\u{1F270}]', // Various symbols
      unicode: true,
    );

    if (emojiRegex.hasMatch(text)) {
      log('UserAvatar: Regex detected emoji in "$text"');
      return true;
    }

    // Check if it's a short string that doesn't look like a URL or file path
    if (text.length <= 4 && !text.contains('.') && !text.contains('/') && !text.contains('http') && !text.contains('www')) {
      log('UserAvatar: Treating short non-URL string as emoji: "$text"');
      return true;
    }

    log('UserAvatar: Not detected as emoji: "$text"');
    return false;
  }

  bool _isNetworkImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) return false;
    return avatar.startsWith('http://') || avatar.startsWith('https://');
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
