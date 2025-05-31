import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;
  final bool showSenderInfo;
  final VoidCallback? onSenderTap;

  const MessageBubble({super.key, required this.message, this.onLongPress, this.showSenderInfo = true, this.onSenderTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromCurrentUser && showSenderInfo) ...[
            GestureDetector(onTap: onSenderTap, child: _buildAvatar(context)),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: _getBubbleColor(colorScheme),
                  borderRadius: _getBorderRadius(),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!message.isFromCurrentUser && message.type != MessageType.system && showSenderInfo)
                      GestureDetector(onTap: onSenderTap, child: _buildSenderName(theme)),
                    _buildMessageContent(theme),
                    const SizedBox(height: 4.0),
                    _buildMessageInfo(theme),
                  ],
                ),
              ),
            ),
          ),
          if (message.isFromCurrentUser) ...[const SizedBox(width: 8.0), _buildAvatar(context)],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (message.type == MessageType.system) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
        child: Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: message.isFromCurrentUser ? colorScheme.primary : colorScheme.secondary,
      child: Text(
        message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
        style: TextStyle(
          color: message.isFromCurrentUser ? colorScheme.onPrimary : colorScheme.onSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSenderName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        message.senderName,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme) {
    final textColor =
        message.type == MessageType.system
            ? theme.colorScheme.onSurfaceVariant
            : message.isFromCurrentUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

    final textStyle =
        message.type == MessageType.system
            ? theme.textTheme.bodySmall?.copyWith(color: textColor, fontStyle: FontStyle.italic)
            : theme.textTheme.bodyMedium?.copyWith(color: textColor);

    return Text(message.content, style: textStyle);
  }

  Widget _buildMessageInfo(ThemeData theme) {
    final infoColor = message.isFromCurrentUser ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateFormat('HH:mm').format(message.timestamp), style: theme.textTheme.labelSmall?.copyWith(color: infoColor, fontSize: 11)),
        if (message.isFromCurrentUser) ...[const SizedBox(width: 4.0), _buildMessageStatusIcon(theme, infoColor)],
      ],
    );
  }

  Widget _buildMessageStatusIcon(ThemeData theme, Color color) {
    IconData icon;
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = theme.colorScheme.primary;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        break;
    }

    return Icon(icon, size: 12, color: color);
  }

  Color _getBubbleColor(ColorScheme colorScheme) {
    if (message.type == MessageType.system) {
      return colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }

    return message.isFromCurrentUser ? colorScheme.primary : colorScheme.surface;
  }

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(16.0);
    const smallRadius = Radius.circular(4.0);

    if (message.type == MessageType.system) {
      return BorderRadius.circular(12.0);
    }

    return BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: message.isFromCurrentUser ? radius : smallRadius,
      bottomRight: message.isFromCurrentUser ? smallRadius : radius,
    );
  }
}
