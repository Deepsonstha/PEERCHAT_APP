import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../widgets/user_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Settings'), backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildProfileSection(context, chatController),
          const SizedBox(height: 24),

          // Appearance Section
          _buildAppearanceSection(context),
          const SizedBox(height: 24),

          // Notification Section
          _buildNotificationSection(context, chatController),
          const SizedBox(height: 24),

          // Network Section
          _buildNetworkSection(context, chatController),
          const SizedBox(height: 24),

          // About Section
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 16),

          // Avatar and Name
          Obx(
            () => Row(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPicker(context, chatController),
                  child: Stack(
                    children: [
                      UserAvatar(user: chatController.currentUser.value, size: 60),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(Icons.edit, size: 12, color: colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatController.currentUser.value?.name ?? 'Unknown User',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text('Tap to change avatar', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showNicknameDialog(context, chatController),
                  icon: Icon(Icons.edit, color: colorScheme.primary),
                  tooltip: 'Edit nickname',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User ID
          Obx(() => _buildInfoRow(context, Icons.fingerprint, 'User ID', chatController.currentUser.value?.id ?? 'Unknown', isMonospace: true)),

          const SizedBox(height: 12),

          // Debug: Current Avatar Value
          Obx(() => _buildInfoRow(context, Icons.face, 'Current Avatar', chatController.currentUser.value?.avatar ?? 'None')),

          const SizedBox(height: 16),

          // Quick emoji test buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  chatController.updateUserAvatar('😀');
                  Get.snackbar('Debug', 'Set avatar to 😀', snackPosition: SnackPosition.BOTTOM);
                },
                child: Text('😀'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  chatController.updateUserAvatar('🎸');
                  Get.snackbar('Debug', 'Set avatar to 🎸', snackPosition: SnackPosition.BOTTOM);
                },
                child: Text('🎸'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  chatController.updateUserAvatar('');
                  Get.snackbar('Debug', 'Cleared avatar', snackPosition: SnackPosition.BOTTOM);
                },
                child: Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 16),

          // Dark Mode Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Toggle between light and dark themes', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Switch(value: isDark, onChanged: (value) => _toggleTheme(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 16),

          Obx(() {
            final settings = chatController.getNotificationSettings();

            return Column(
              children: [
                // General Notifications
                _buildNotificationToggle(
                  context,
                  Icons.notifications,
                  'Notifications',
                  'Enable all notifications',
                  settings['notificationsEnabled'] ?? true,
                  (value) => chatController.updateNotificationSettings(notificationsEnabled: value),
                ),
                const SizedBox(height: 16),

                // Private Message Notifications
                _buildNotificationToggle(
                  context,
                  Icons.message,
                  'Private Messages',
                  'Get notified of private messages',
                  settings['privateMessageNotifications'] ?? true,
                  (value) => chatController.updateNotificationSettings(privateMessageNotifications: value),
                ),
                const SizedBox(height: 16),

                // Sound
                _buildNotificationToggle(
                  context,
                  Icons.volume_up,
                  'Sound',
                  'Play notification sounds',
                  settings['soundEnabled'] ?? true,
                  (value) => chatController.updateNotificationSettings(soundEnabled: value),
                ),
                const SizedBox(height: 16),

                // Vibration
                _buildNotificationToggle(
                  context,
                  Icons.vibration,
                  'Vibration',
                  'Vibrate for notifications',
                  settings['vibrationEnabled'] ?? true,
                  (value) => chatController.updateNotificationSettings(vibrationEnabled: value),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context, IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildNetworkSection(BuildContext context, ChatController chatController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Network', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const Spacer(),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chatController.isConnected.value ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chatController.isConnected.value ? Icons.wifi : Icons.wifi_off,
                        size: 14,
                        color: chatController.isConnected.value ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chatController.isConnected.value ? 'Connected' : 'Disconnected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: chatController.isConnected.value ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Obx(() {
            final networkInfo = chatController.getNetworkInfo();
            return Column(
              children: [
                _buildInfoRow(context, Icons.devices, 'Protocol', networkInfo['protocol']),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.people, 'Connected Users', '${networkInfo['userCount']}'),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.router, 'Discovery Port', '${networkInfo['discoveryPort']}'),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.message, 'Message Port', '${networkInfo['messagePort']}'),
                const SizedBox(height: 16),

                // Network Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: chatController.isConnected.value ? null : () => _startP2PNetwork(context, chatController),
                        icon: const Icon(Icons.wifi),
                        label: const Text('Start P2P'),
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !chatController.isConnected.value ? null : () => _stopP2PNetwork(context, chatController),
                        icon: const Icon(Icons.wifi_off),
                        label: const Text('Stop P2P'),
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fast Scanning Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !chatController.isConnected.value ? null : () => _forceScan(context, chatController),
                        icon: const Icon(Icons.radar),
                        label: const Text('Force Scan'),
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !chatController.isConnected.value ? null : () => _showScanningInfo(context, chatController),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Scan Info'),
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.tertiary, foregroundColor: colorScheme.onTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 16),

          _buildInfoRow(context, Icons.info, 'App Version', '1.0.0'),
          const SizedBox(height: 12),
          _buildInfoRow(context, Icons.code, 'Built with', 'Flutter & GetX'),
          const SizedBox(height: 12),
          _buildInfoRow(context, Icons.security, 'Encryption', 'P2P UDP'),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPrivacyPolicy(context),
                  icon: const Icon(Icons.privacy_tip),
                  label: const Text('Privacy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(onPressed: () => _showLicenses(context), icon: const Icon(Icons.article), label: const Text('Licenses')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isMonospace = false}) {
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
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: isMonospace ? 'monospace' : null)),
            ],
          ),
        ),
      ],
    );
  }

  void _showNicknameDialog(BuildContext context, ChatController chatController) {
    final TextEditingController nicknameController = TextEditingController(text: chatController.currentUser.value?.name ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Nickname'),
            content: TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: 'Nickname', hintText: 'Enter your nickname', border: OutlineInputBorder()),
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newName = nicknameController.text.trim();
                  if (newName.isNotEmpty) {
                    chatController.updateUserName(newName);
                    Navigator.pop(context);
                    Get.snackbar('Nickname Updated', 'Your nickname has been changed to "$newName"', snackPosition: SnackPosition.BOTTOM);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showAvatarPicker(BuildContext context, ChatController chatController) {
    final List<String> avatarEmojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Avatar'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 1),
                itemCount: avatarEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = avatarEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      chatController.updateUserAvatar(emoji);
                      Navigator.pop(context);
                      Get.snackbar('Avatar Updated', 'Your avatar has been changed', snackPosition: SnackPosition.BOTTOM);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
          ),
    );
  }

  void _toggleTheme(BuildContext context) {
    // TODO: Implement theme switching with GetX
    Get.snackbar('Theme', 'Theme switching will be implemented', snackPosition: SnackPosition.BOTTOM);
  }

  void _startP2PNetwork(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start P2P Network'),
            content: const Text('This will start the peer-to-peer network and make you discoverable to other users.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  chatController.connectToServer();
                  Get.snackbar('P2P Network', 'Starting peer-to-peer network...', snackPosition: SnackPosition.BOTTOM);
                },
                child: const Text('Start'),
              ),
            ],
          ),
    );
  }

  void _stopP2PNetwork(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Stop P2P Network'),
            content: const Text('This will disconnect you from the peer-to-peer network.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  chatController.disconnectFromServer();
                  Get.snackbar('P2P Network', 'Disconnected from peer-to-peer network', snackPosition: SnackPosition.BOTTOM);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
    );
  }

  void _forceScan(BuildContext context, ChatController chatController) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [Icon(Icons.radar, color: Theme.of(context).colorScheme.secondary), const SizedBox(width: 8), const Text('Force Scan')],
            ),
            content: const Text('This will trigger immediate super fast device discovery. Use this to quickly find nearby devices.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  chatController.forceScan();
                  Get.snackbar(
                    'Fast Scanning',
                    'Super fast device discovery activated!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    colorText: Theme.of(context).colorScheme.secondary,
                    icon: Icon(Icons.radar, color: Theme.of(context).colorScheme.secondary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('Force Scan'),
              ),
            ],
          ),
    );
  }

  void _showScanningInfo(BuildContext context, ChatController chatController) {
    final networkInfo = chatController.getNetworkInfo();
    final scanningMode = networkInfo['scanningMode'] ?? 'unknown';
    final isFastScanning = networkInfo['isFastScanning'] ?? false;
    final isBurstScanning = networkInfo['isBurstScanning'] ?? false;
    final discoveredUsers = networkInfo['discoveredUsers'] ?? 0;
    final lastNewUserFound = networkInfo['lastNewUserFound'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                const Text('Scanning Information'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScanInfoRow(context, 'Scanning Mode', scanningMode.toString().toUpperCase()),
                const SizedBox(height: 8),
                _buildScanInfoRow(context, 'Fast Scanning', isFastScanning ? 'ACTIVE' : 'INACTIVE'),
                const SizedBox(height: 8),
                _buildScanInfoRow(context, 'Burst Scanning', isBurstScanning ? 'ACTIVE' : 'INACTIVE'),
                const SizedBox(height: 8),
                _buildScanInfoRow(context, 'Discovered Users', discoveredUsers.toString()),
                const SizedBox(height: 8),
                _buildScanInfoRow(context, 'Last User Found', lastNewUserFound != null ? 'Recently' : 'None'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scanning Modes:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '• BURST: 100ms intervals (10 scans)\n• FAST: 500ms intervals\n• NORMAL: 2s intervals',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
    );
  }

  Widget _buildScanInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final currentYear = DateTime.now().year;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: SingleChildScrollView(
              child: Text(
                'PeerChat Privacy Policy\n\n'
                '1. Data Collection: We do not collect any personal data. All messages are sent directly between devices.\n\n'
                '2. Message Storage: Messages are stored locally on your device only.\n\n'
                '3. Network Communication: All communication uses peer-to-peer UDP protocol.\n\n'
                '4. No Servers: No central servers are used to store or relay messages.\n\n'
                '5. Encryption: Messages are transmitted using P2P encryption protocols.\n\n'
                'Last updated: $currentYear',
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'PeerChat',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 PeerChat. Built with Flutter.',
    );
  }
}
