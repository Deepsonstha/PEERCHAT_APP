import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../data/models/user.dart';

class AllUsersScreen extends StatelessWidget {
  final List<User> users;
  final User? currentUser;

  const AllUsersScreen({super.key, required this.users, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Online Users (${users.length})')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => _showNetworkInfo(context), icon: const Icon(Icons.info_outline), tooltip: 'Network Information'),
          IconButton(onPressed: () => _refreshUsers(), icon: const Icon(Icons.refresh), tooltip: 'Refresh Users'),
        ],
      ),
      body:
          users.isEmpty
              ? _buildEmptyState(context)
              : Column(
                children: [
                  // Network status header
                  _buildNetworkHeader(context),

                  // Users list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isCurrentUser = currentUser?.id == user.id;
                        return _buildUserCard(context, user, isCurrentUser);
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => _forceScan(),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            heroTag: "forceScan",
            tooltip: 'Force Scan',
            child: const Icon(Icons.radar),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _refreshUsers(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            heroTag: "refresh",
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
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
          Icon(Icons.people_outline, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Users Connected', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Start P2P chat to discover other users\non the same WiFi network',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back), label: const Text('Back to Chat')),
        ],
      ),
    );
  }

  Widget _buildNetworkHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.wifi, color: colorScheme.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('P2P Network Active', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                Text('Discovering users on local WiFi network', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${users.length} Online',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, bool isCurrentUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser ? BorderSide(color: colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showUserDetails(context, user, isCurrentUser),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // User avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isCurrentUser ? colorScheme.primary : _getUserColor(user.id, colorScheme),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: isCurrentUser ? colorScheme.onPrimary : Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              'You',
                              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.id.substring(0, 8)}...',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Last seen: ${_formatLastSeen(user.lastSeen)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status indicator
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Online', style: theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUserColor(String userId, ColorScheme colorScheme) {
    final colors = [colorScheme.secondary, colorScheme.tertiary, Colors.purple, Colors.indigo, Colors.teal, Colors.orange, Colors.pink, Colors.cyan];

    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
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

  void _showUserDetails(BuildContext context, User user, bool isCurrentUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isCurrentUser ? colorScheme.primary : _getUserColor(user.id, colorScheme),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: isCurrentUser ? colorScheme.onPrimary : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleLarge),
                      if (isCurrentUser)
                        Text('You', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, Icons.person, 'User ID', user.id),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.access_time, 'Last Seen', _formatLastSeen(user.lastSeen)),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.circle, 'Status', 'Online', valueColor: Colors.green),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.wifi, 'Connection', 'P2P Network'),
                if (isCurrentUser) ...[const SizedBox(height: 12), _buildDetailRow(context, Icons.devices, 'Device', 'This Device')],
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? colorScheme.onSurface,
                  fontFamily: label == 'User ID' ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNetworkInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(children: [Icon(Icons.wifi, color: colorScheme.primary), const SizedBox(width: 8), const Text('Network Information')]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, Icons.network_wifi, 'Protocol', 'UDP Broadcast'),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.router, 'Discovery Port', '8888'),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.message, 'Message Port', '8889'),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.people, 'Connected Users', '${users.length}'),
                const SizedBox(height: 12),
                _buildDetailRow(context, Icons.security, 'Network Scope', 'Local WiFi Only'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How it works:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '• Devices broadcast their presence every 5 seconds\n'
                        '• Messages are sent directly between devices\n'
                        '• No internet or server required\n'
                        '• Works only on same WiFi network',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
    );
  }

  void _forceScan() {
    final chatController = Get.find<ChatController>();
    chatController.forceScan();

    Get.snackbar(
      'Fast Scanning',
      'Super fast device discovery activated!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(Get.context!).colorScheme.secondary.withOpacity(0.2),
      colorText: Theme.of(Get.context!).colorScheme.secondary,
      icon: Icon(Icons.radar, color: Theme.of(Get.context!).colorScheme.secondary),
      duration: const Duration(seconds: 2),
    );
  }

  void _refreshUsers() {
    final chatController = Get.find<ChatController>();
    chatController.refreshUserDiscovery();

    Get.snackbar(
      'Refreshing',
      'Searching for nearby devices...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.2),
      colorText: Theme.of(Get.context!).colorScheme.primary,
      icon: Icon(Icons.refresh, color: Theme.of(Get.context!).colorScheme.primary),
      duration: const Duration(seconds: 1),
    );
  }
}
