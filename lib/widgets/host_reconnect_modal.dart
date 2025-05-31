import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/user.dart';

class HostReconnectModal extends StatefulWidget {
  final User? newHost;
  final bool isElecting;
  final VoidCallback? onDismiss;

  const HostReconnectModal({super.key, this.newHost, this.isElecting = true, this.onDismiss});

  @override
  State<HostReconnectModal> createState() => _HostReconnectModalState();
}

class _HostReconnectModalState extends State<HostReconnectModal> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.linear));

    if (widget.isElecting) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HostReconnectModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isElecting != oldWidget.isElecting) {
      if (widget.isElecting) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isElecting ? _scaleAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: widget.isElecting ? _rotationAnimation.value * 2 * 3.14159 : 0,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: widget.isElecting ? colorScheme.primary.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.isElecting ? colorScheme.primary : Colors.green, width: 3),
                        ),
                        child: Icon(
                          widget.isElecting ? Icons.sync : Icons.check_circle,
                          size: 40,
                          color: widget.isElecting ? colorScheme.primary : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                widget.isElecting ? 'Host Election in Progress' : 'New Host Selected',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                widget.isElecting
                    ? 'The current host has left the network. A new host is being selected automatically...'
                    : 'Network connection has been restored with a new host.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              if (!widget.isElecting && widget.newHost != null) ...[
                const SizedBox(height: 20),

                // New host info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          widget.newHost!.name.isNotEmpty ? widget.newHost!.name[0].toUpperCase() : '?',
                          style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Host',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            ),
                            Text(widget.newHost!.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                ),
              ],

              if (widget.isElecting) ...[
                const SizedBox(height: 20),

                // Progress indicator
                LinearProgressIndicator(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),

                const SizedBox(height: 12),

                Text(
                  'Please wait while the network reorganizes...',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (!widget.isElecting) ...[
                    Expanded(child: OutlinedButton(onPressed: widget.onDismiss, child: const Text('Dismiss'))),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          widget.isElecting
                              ? null
                              : () {
                                widget.onDismiss?.call();
                                Get.snackbar(
                                  'Network Restored',
                                  'Connection to the P2P network has been restored',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.withOpacity(0.2),
                                  colorText: Colors.green,
                                );
                              },
                      icon: Icon(widget.isElecting ? Icons.hourglass_empty : Icons.check),
                      label: Text(widget.isElecting ? 'Waiting...' : 'Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isElecting ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                        foregroundColor: widget.isElecting ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              if (widget.isElecting) ...[
                const SizedBox(height: 16),

                // Additional info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The network will automatically select the most suitable device as the new host',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the modal
void showHostReconnectModal({required BuildContext context, User? newHost, bool isElecting = true, VoidCallback? onDismiss}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => HostReconnectModal(newHost: newHost, isElecting: isElecting, onDismiss: onDismiss ?? () => Navigator.of(context).pop()),
  );
}
