import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isConnected;
  final VoidCallback? onAttachFile;
  final String? hintText;

  const MessageInput({super.key, required this.onSendMessage, required this.isConnected, this.onAttachFile, this.hintText});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isNotEmpty && widget.isConnected) {
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surface, border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Attach file button
              if (widget.onAttachFile != null)
                IconButton(
                  onPressed: widget.isConnected ? widget.onAttachFile : null,
                  icon: Icon(
                    Icons.attach_file,
                    color: widget.isConnected ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  tooltip: 'Attach file',
                ),

              // Text input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: _focusNode.hasFocus ? colorScheme.primary : colorScheme.outline.withOpacity(0.3), width: 1),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: _handleTextChanged,
                    onSubmitted: _handleSubmitted,
                    enabled: widget.isConnected,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: widget.isConnected ? (widget.hintText ?? 'Type a message...') : 'Disconnected',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    ),
                    style: TextStyle(color: widget.isConnected ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  ),
                ),
              ),

              const SizedBox(width: 8.0),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child:
                    _isComposing && widget.isConnected
                        ? FloatingActionButton.small(
                          onPressed: () => _handleSubmitted(_textController.text),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 2,
                          child: const Icon(Icons.send),
                        )
                        : FloatingActionButton.small(
                          onPressed: null,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          elevation: 0,
                          child: const Icon(Icons.send),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
