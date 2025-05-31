import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../data/models/chat_message.dart';
import '../data/models/user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';

class PrivateChatScreen extends StatelessWidget {
  final User user;

  const PrivateChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: colorScheme.onSurface)),
        title: Row(
          children: [
            UserAvatar(user: user, size: 35, showOnlineIndicator: true, onTap: () => _showUserProfile(context, user)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    user.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: user.isOnline ? Colors.green : colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () => _showChatInfo(context, user, chatController), icon: Icon(Icons.info_outline, color: colorScheme.onSurface)),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, chatController),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.clear_all), SizedBox(width: 8), Text('Clear Chat')])),
                  const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block), SizedBox(width: 8), Text('Block User')])),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Obx(() {
              final privateMessages = _getPrivateMessages(chatController.messages, user.id, chatController.currentUser.value?.id);

              if (privateMessages.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: privateMessages.length,
                itemBuilder: (context, index) {
                  final message = privateMessages[index];
                  final previousMessage = index > 0 ? privateMessages[index - 1] : null;
                  final nextMessage = index < privateMessages.length - 1 ? privateMessages[index + 1] : null;

                  final showSenderInfo =
                      previousMessage == null ||
                      previousMessage.senderId != message.senderId ||
                      message.timestamp.difference(previousMessage.timestamp).inMinutes > 5;

                  final isLastInGroup =
                      nextMessage == null ||
                      nextMessage.senderId != message.senderId ||
                      nextMessage.timestamp.difference(message.timestamp).inMinutes > 5;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLastInGroup ? 12 : 2),
                    child: _buildPrivateMessageBubble(context, message, showSenderInfo, chatController),
                  );
                },
              );
            }),
          ),

          // Typing indicator
          _buildTypingIndicator(context),

          // Message input
          Obx(
            () => MessageInput(
              onSendMessage: (content) => _sendPrivateMessage(content, chatController),
              isConnected: chatController.isConnected.value,
              onAttachFile: () => _showAttachmentOptions(context),
              hintText: 'Message ${user.name}...',
            ),
          ),
        ],
      ),
    );
  }

  List<ChatMessage> _getPrivateMessages(List<ChatMessage> allMessages, String otherUserId, String? currentUserId) {
    return allMessages.where((message) {
      // For now, show all messages in private chat
      // TODO: Implement actual private messaging logic
      return true;
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UserAvatar(user: user, size: 80),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Start your private conversation', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.lock, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text('Private & Secure', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Messages are sent directly between devices using P2P encryption',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateMessageBubble(BuildContext context, ChatMessage message, bool showSenderInfo, ChatController chatController) {
    return MessageBubble(
      message: message,
      showSenderInfo: false, // Don't show sender info in private chat
      onLongPress: () => _showMessageOptions(context, message, chatController),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    // TODO: Implement typing indicator for private chat
    return const SizedBox.shrink();
  }

  void _sendPrivateMessage(String content, ChatController chatController) {
    // TODO: Implement private message sending logic
    // For now, send as regular message
    chatController.sendMessage(content);
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleMenuAction(BuildContext context, String action, ChatController chatController) {
    switch (action) {
      case 'clear':
        _showClearChatDialog(context, chatController);
        break;
      case 'block':
        _showBlockUserDialog(context, user);
        break;
    }
  }

  void _showUserProfile(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                UserAvatar(user: user, size: 50),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name),
                      Text(
                        user.isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: user.isOnline ? Colors.green : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow(context, Icons.person, 'User ID', user.id),
                const SizedBox(height: 12),
                _buildProfileRow(context, Icons.access_time, 'Last Seen', _formatLastSeen(user.lastSeen)),
                const SizedBox(height: 12),
                _buildProfileRow(context, Icons.wifi, 'Connection', 'P2P Network'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
    );
  }

  Widget _buildProfileRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: label == 'User ID' ? 'monospace' : null)),
            ],
          ),
        ),
      ],
    );
  }

  void _showChatInfo(BuildContext context, User user, ChatController chatController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      UserAvatar(user: user, size: 80),
                      const SizedBox(height: 16),
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        user.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: user.isOnline ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: Switch(
                          value: true, // TODO: Implement notification settings
                          onChanged: (value) {
                            // TODO: Handle notification toggle
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.wallpaper),
                        title: const Text('Wallpaper'),
                        onTap: () {
                          // TODO: Implement wallpaper selection
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
                        title: Text('Block User', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        onTap: () {
                          Navigator.pop(context);
                          _showBlockUserDialog(context, user);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: Text('Clear all messages with ${user.name}? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement clear private chat
                  Navigator.pop(context);
                  Get.snackbar('Chat Cleared', 'Messages with ${user.name} have been cleared', snackPosition: SnackPosition.BOTTOM);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _showBlockUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Block User'),
            content: Text('Block ${user.name}? They won\'t be able to send you messages.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement user blocking
                  Navigator.pop(context);
                  Get.back(); // Go back to previous screen
                  Get.snackbar('User Blocked', '${user.name} has been blocked', snackPosition: SnackPosition.BOTTOM);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Block'),
              ),
            ],
          ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message, ChatController chatController) {
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
                    leading: const Icon(Icons.reply),
                    title: const Text('Reply'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement reply functionality
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement copy functionality
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.forward),
                    title: const Text('Forward'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement forward functionality
                    },
                  ),
                  if (message.isFromCurrentUser)
                    ListTile(
                      leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: () {
                        Navigator.pop(context);
                        chatController.deleteMessage(message.id);
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
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
                    leading: const Icon(Icons.photo),
                    title: const Text('Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement photo attachment
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: const Text('File'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement file attachment
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }
}
