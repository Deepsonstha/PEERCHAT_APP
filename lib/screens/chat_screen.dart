import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../screens/all_users_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/online_users_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerChat - Local P2P'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Connection status indicator
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: chatController.isConnected.value ? Colors.green : Colors.orange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    chatController.isConnected.value ? 'P2P Active' : 'P2P Inactive',
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
                  const PopupMenuItem(value: 'connect', child: Row(children: [Icon(Icons.wifi), SizedBox(width: 8), Text('Start P2P Chat')])),
                  const PopupMenuItem(value: 'users', child: Row(children: [Icon(Icons.people), SizedBox(width: 8), Text('View All Users')])),
                  const PopupMenuItem(value: 'disconnect', child: Row(children: [Icon(Icons.wifi_off), SizedBox(width: 8), Text('Stop P2P')])),
                  const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.clear_all), SizedBox(width: 8), Text('Clear Messages')])),
                  const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Settings')])),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Online users section
          Obx(() => OnlineUsersWidget(onlineUsers: chatController.onlineUsers, currentUser: chatController.currentUser.value)),

          // Messages list
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No messages yet', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation!',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = chatController.messages[index];
                  return MessageBubble(message: message, onLongPress: () => _showMessageOptions(context, message.id, chatController));
                },
              );
            }),
          ),

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

  void _handleMenuAction(BuildContext context, String action, ChatController chatController) {
    switch (action) {
      case 'connect':
        _showConnectDialog(context, chatController);
        break;
      case 'users':
        _showAllUsers(context, chatController);
        break;
      case 'disconnect':
        chatController.disconnectFromServer();
        Get.snackbar('Disconnected', 'You have been disconnected from the server', snackPosition: SnackPosition.BOTTOM);
        break;
      case 'clear':
        _showClearMessagesDialog(context, chatController);
        break;
      case 'settings':
        _showSettingsDialog(context, chatController);
        break;
    }
  }

  void _showConnectDialog(BuildContext context, ChatController chatController) {
    final TextEditingController nameController = TextEditingController();

    // Pre-fill with current user name if available
    if (chatController.currentUser.value != null) {
      nameController.text = chatController.currentUser.value!.name;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start P2P Chat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Your Name', hintText: 'Enter your display name')),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wifi, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Local Network Mode',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• No internet required\n• Works on same WiFi network\n• Fully offline peer-to-peer chat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    await chatController.createUser(name);
                    await chatController.connectToServer(); // No server URL needed for P2P
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Start P2P Chat'),
              ),
            ],
          ),
    );
  }

  void _showAllUsers(BuildContext context, ChatController chatController) {
    Get.to(() => AllUsersScreen(users: chatController.onlineUsers, currentUser: chatController.currentUser.value));
  }

  void _showClearMessagesDialog(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Messages'),
            content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  chatController.clearAllMessages();
                  Navigator.of(context).pop();
                  Get.snackbar('Messages Cleared', 'All messages have been cleared', snackPosition: SnackPosition.BOTTOM);
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

  void _showSettingsDialog(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current User: ${chatController.currentUser.value?.name ?? 'Not set'}'),
                const SizedBox(height: 8),
                Text('Messages: ${chatController.messages.length}'),
                const SizedBox(height: 8),
                Text('Online Users: ${chatController.onlineUsersCount}'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
    );
  }

  void _showMessageOptions(BuildContext context, String messageId, ChatController chatController) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Message'),
                  onTap: () {
                    chatController.deleteMessage(messageId);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy Message'),
                  onTap: () {
                    // TODO: Implement copy functionality
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement photo attachment
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('File'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement file attachment
                  },
                ),
              ],
            ),
          ),
    );
  }
}
