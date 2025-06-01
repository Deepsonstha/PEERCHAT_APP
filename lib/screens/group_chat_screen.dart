import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../data/models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Chat'),
            Obx(
              () => Text(
                '${chatController.onlineUsersCount} members online',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        actions: [
          // Online users avatars
          Obx(
            () => Container(
              width: 120,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ...chatController.onlineUsers.take(3).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return Positioned(right: index * 20.0, child: UserAvatar(user: user, size: 32, showOnlineIndicator: true));
                  }),
                  if (chatController.onlineUsers.length > 3)
                    Positioned(
                      right: 60,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '+${chatController.onlineUsers.length - 3}',
                            style: TextStyle(color: colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Menu button
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, chatController),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'members', child: Row(children: [Icon(Icons.people), SizedBox(width: 8), Text('View Members')])),
                  const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.clear_all), SizedBox(width: 8), Text('Clear Chat')])),
                  const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Chat Settings')])),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          Obx(
            () =>
                !chatController.isConnected.value
                    ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.withOpacity(0.2),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text('Disconnected from P2P network', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),

          // Messages list
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatController.messages.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: chatController.messages.length + 1, // +1 for typing indicator
                itemBuilder: (context, index) {
                  if (index == chatController.messages.length) {
                    return _buildTypingIndicator(context);
                  }

                  final message = chatController.messages[index];
                  final previousMessage = index > 0 ? chatController.messages[index - 1] : null;
                  final showSenderInfo =
                      previousMessage == null ||
                      previousMessage.senderId != message.senderId ||
                      message.timestamp.difference(previousMessage.timestamp).inMinutes > 5;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMessageBubble(context, message, showSenderInfo, chatController),
                  );
                },
              );
            }),
          ),

          // Typing users indicator
          _buildTypingUsersIndicator(context, chatController),

          // Message input
          Obx(
            () => MessageInput(
              onSendMessage: chatController.sendMessage,
              isConnected: chatController.isConnected.value,
              onAttachFile: () => _showAttachmentOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Welcome to Group Chat!',
            style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.tips_and_updates, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text('Tips:', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '• Messages are shared with all connected users\n'
                  '• Long press messages for options\n'
                  '• Tap user avatars to start private chats',
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

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, bool showSenderInfo, ChatController chatController) {
    return MessageBubble(
      message: message,
      showSenderInfo: showSenderInfo,
      onLongPress: () => _showMessageOptions(context, message, chatController),
      onSenderTap: message.isFromCurrentUserValue ? null : () => _showSenderOptions(context, message, chatController),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    // TODO: Implement typing indicator based on real typing users
    return const SizedBox.shrink();
  }

  Widget _buildTypingUsersIndicator(BuildContext context, ChatController chatController) {
    // TODO: Implement typing users indicator
    return const SizedBox.shrink();
  }

  void _handleMenuAction(BuildContext context, String action, ChatController chatController) {
    switch (action) {
      case 'members':
        _showMembersDialog(context, chatController);
        break;
      case 'clear':
        _showClearChatDialog(context, chatController);
        break;
      case 'settings':
        _showChatSettings(context, chatController);
        break;
    }
  }

  void _showMembersDialog(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Group Members (${chatController.onlineUsersCount})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: chatController.onlineUsers.length,
                itemBuilder: (context, index) {
                  final user = chatController.onlineUsers[index];
                  final isCurrentUser = user.id == chatController.currentUser.value?.id;

                  return ListTile(
                    leading: UserAvatar(user: user, size: 40, showOnlineIndicator: true),
                    title: Text(user.name),
                    subtitle: Text(isCurrentUser ? 'You' : 'Online'),
                    trailing: isCurrentUser ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary) : null,
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  chatController.clearAllMessages();
                  Navigator.pop(context);
                  Get.snackbar('Chat Cleared', 'All messages have been cleared', snackPosition: SnackPosition.BOTTOM);
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

  void _showChatSettings(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chat Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Message Notifications'),
                  subtitle: const Text('Get notified of new messages'),
                  value: true, // TODO: Implement settings
                  onChanged: (value) {
                    // TODO: Implement notification settings
                  },
                ),
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Play sounds for message events'),
                  value: true, // TODO: Implement settings
                  onChanged: (value) {
                    // TODO: Implement sound settings
                  },
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
                  if (message.isFromCurrentUserValue)
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

  void _showSenderOptions(BuildContext context, ChatMessage message, ChatController chatController) {
    final user = chatController.getUserById(message.senderId);
    if (user == null) return;

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
                  ListTile(leading: UserAvatar(user: user, size: 40), title: Text(user.name), subtitle: const Text('Tap to view options')),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Start Private Chat'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to private chat
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('View Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Show user profile
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
