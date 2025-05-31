import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../data/models/user.dart';
import '../screens/group_chat_screen.dart';
import '../screens/private_chat_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              boxShadow: [
                BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Top row with title and actions
                    Row(
                      children: [
                        Text('PeerChat', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        const Spacer(),
                        // Connection status
                        Obx(
                          () => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: chatController.isConnected.value ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: chatController.isConnected.value ? Colors.green : Colors.orange, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: chatController.isConnected.value ? Colors.green : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  chatController.isConnected.value ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: chatController.isConnected.value ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Settings button
                        IconButton(
                          onPressed: () => Get.to(() => const SettingsScreen()),
                          icon: Icon(Icons.settings, color: colorScheme.onSurface, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // User info and stats row
                    Obx(
                      () => Row(
                        children: [
                          // Current user info
                          UserAvatar(user: chatController.currentUser.value, size: 36, showOnlineIndicator: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        chatController.currentUser.value?.name ?? 'Guest',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                                      child: Text(
                                        'You',
                                        style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Host • P2P Network',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Quick stats
                          Row(
                            children: [
                              _buildQuickStat(context, Icons.people, '${chatController.onlineUsersCount}'),
                              const SizedBox(width: 16),
                              _buildQuickStat(context, Icons.message, '${chatController.messages.length}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Online users section
          Expanded(child: Obx(() => _buildOnlineUsersSection(context, chatController))),

          // Action buttons
          _buildActionButtons(context, chatController),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.primary, size: 16),
        const SizedBox(width: 4),
        Text(value, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildOnlineUsersSection(BuildContext context, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (chatController.onlineUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No users online', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(
              'Start P2P chat to discover users',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Online Users (${chatController.onlineUsers.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chatController.onlineUsers.length,
            itemBuilder: (context, index) {
              final user = chatController.onlineUsers[index];
              final isCurrentUser = user.id == chatController.currentUser.value?.id;

              return _buildUserCard(context, user, isCurrentUser, chatController);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, User user, bool isCurrentUser, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser ? Border.all(color: colorScheme.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrentUser ? null : () => _showUserOptions(context, user, chatController),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatar(user: user, size: 45, showOnlineIndicator: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                              child: Text('You', style: TextStyle(color: colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Host', // TODO: Implement host detection
                              style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last seen: ${_formatLastSeen(user.lastSeen)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCurrentUser) Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Join Group Chat button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const GroupChatScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 8,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 24),
                  const SizedBox(width: 12),
                  Text('Join Group Chat', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Start Private Chat button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _showUserSelector(context, chatController),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 24),
                  const SizedBox(width: 12),
                  Text('Start Private Chat', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
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

  void _showUserOptions(BuildContext context, User user, ChatController chatController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Start Private Chat'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => PrivateChatScreen(user: user));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).colorScheme.onSurface),
                    title: const Text('View Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      _showUserProfile(context, user);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  void _showUserSelector(BuildContext context, ChatController chatController) {
    if (chatController.onlineUsers.isEmpty) {
      Get.snackbar('No Users Available', 'No other users are currently online', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Select User for Private Chat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: chatController.onlineUsers.length,
                    itemBuilder: (context, index) {
                      final user = chatController.onlineUsers[index];
                      final isCurrentUser = user.id == chatController.currentUser.value?.id;

                      if (isCurrentUser) return const SizedBox.shrink();

                      return ListTile(
                        leading: UserAvatar(user: user, size: 40),
                        title: Text(user.name),
                        subtitle: Text('Last seen: ${_formatLastSeen(user.lastSeen)}'),
                        onTap: () {
                          Navigator.pop(context);
                          Get.to(() => PrivateChatScreen(user: user));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showUserProfile(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(children: [UserAvatar(user: user, size: 40), const SizedBox(width: 12), Expanded(child: Text(user.name))]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${user.id}'),
                const SizedBox(height: 8),
                Text('Status: Online'),
                const SizedBox(height: 8),
                Text('Last seen: ${_formatLastSeen(user.lastSeen)}'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
    );
  }
}
