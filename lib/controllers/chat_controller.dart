import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../data/models/chat_message.dart';
import '../data/models/user.dart';
import '../data/repositories/chat_repository.dart';

class ChatController extends GetxController {
  final ChatRepository _chatRepository = Get.find<ChatRepository>();

  // Observable variables
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxList<User> onlineUsers = <User>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isLoading = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;
  final Rx<User?> currentUser = Rx<User?>(null);

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _onlineUsersSubscription;
  StreamSubscription? _connectionSubscription;

  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  /// Initialize chat functionality if not already initialized
  Future<void> initializeIfNeeded() async {
    if (_isInitialized) return;
    await _initializeChat();
  }

  /// Initialize chat functionality
  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    try {
      log('Initializing chat controller...');
      isLoading.value = true;

      // Initialize repository
      await _chatRepository.init();
      log('Repository initialized');

      // Load current user
      final user = _chatRepository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        log('Current user loaded: ${user.name}');
      } else {
        log('No current user found');
      }

      // Load messages from local storage
      _loadLocalMessages();

      // Setup stream listeners
      _setupStreamListeners();

      _isInitialized = true;
      log('Chat controller initialized successfully');
    } catch (e) {
      log('Error initializing chat: $e');
      // Don't throw error, let the app continue
      Get.snackbar(
        'Initialization Warning',
        'Some features may not work properly: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load messages from local storage
  void _loadLocalMessages() {
    try {
      final localMessages = _chatRepository.getAllMessages();
      messages.assignAll(localMessages);
      log('Loaded ${localMessages.length} messages from storage');
    } catch (e) {
      log('Error loading local messages: $e');
    }
  }

  /// Setup stream listeners for real-time updates
  void _setupStreamListeners() {
    try {
      // Listen for incoming messages
      _messageSubscription = _chatRepository.messageStream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          log('Error in message stream: $error');
        },
      );

      // Listen for users joining
      _userJoinedSubscription = _chatRepository.userJoinedStream.listen(
        (user) {
          _handleUserJoined(user);
        },
        onError: (error) {
          log('Error in user joined stream: $error');
        },
      );

      // Listen for users leaving
      _userLeftSubscription = _chatRepository.userLeftStream.listen(
        (user) {
          _handleUserLeft(user);
        },
        onError: (error) {
          log('Error in user left stream: $error');
        },
      );

      // Listen for online users updates
      _onlineUsersSubscription = _chatRepository.onlineUsersStream.listen(
        (users) {
          onlineUsers.assignAll(users);
        },
        onError: (error) {
          log('Error in online users stream: $error');
        },
      );

      // Listen for connection status changes
      _connectionSubscription = _chatRepository.connectionStream.listen(
        (connected) {
          isConnected.value = connected;
          connectionStatus.value = connected ? 'Connected' : 'Disconnected';

          if (connected) {
            log('P2P network connected');
            _chatRepository.requestOnlineUsers();
          } else {
            log('P2P network disconnected');
            onlineUsers.clear();
          }
        },
        onError: (error) {
          log('Error in connection stream: $error');
        },
      );

      log('Stream listeners setup complete');
    } catch (e) {
      log('Error setting up stream listeners: $e');
    }
  }

  /// Handle incoming message
  void _handleIncomingMessage(ChatMessage message) async {
    try {
      // Mark as not from current user if it's from someone else
      if (currentUser.value != null && message.senderId != currentUser.value!.id) {
        message.isFromCurrentUser = false;
      }

      // Save to local storage
      await _chatRepository.saveReceivedMessage(message);

      // Add to messages list if not already present
      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex == -1) {
        messages.add(message);
        _sortMessages();
        log('Received message: ${message.content}');
      }
    } catch (e) {
      log('Error handling incoming message: $e');
    }
  }

  /// Handle user joined
  void _handleUserJoined(User user) {
    try {
      final existingIndex = onlineUsers.indexWhere((u) => u.id == user.id);
      if (existingIndex == -1) {
        onlineUsers.add(user);
        log('User joined: ${user.name}');
      }

      // Add system message
      _addSystemMessage('${user.name} joined the chat');
    } catch (e) {
      log('Error handling user joined: $e');
    }
  }

  /// Handle user left
  void _handleUserLeft(User user) {
    try {
      onlineUsers.removeWhere((u) => u.id == user.id);
      log('User left: ${user.name}');

      // Add system message
      _addSystemMessage('${user.name} left the chat');
    } catch (e) {
      log('Error handling user left: $e');
    }
  }

  /// Add system message
  void _addSystemMessage(String content) {
    try {
      final systemMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: 'system',
        senderName: 'System',
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.system,
        isFromCurrentUser: false,
        status: MessageStatus.delivered,
      );

      messages.add(systemMessage);
      _chatRepository.saveReceivedMessage(systemMessage);
    } catch (e) {
      log('Error adding system message: $e');
    }
  }

  /// Connect to chat server
  Future<void> connectToServer({String? serverUrl}) async {
    try {
      if (currentUser.value == null) {
        throw Exception('No current user set. Please create a user first.');
      }

      log('Connecting to P2P network...');
      isLoading.value = true;
      connectionStatus.value = 'Connecting...';

      await _chatRepository.connect(serverUrl: serverUrl, currentUser: currentUser.value);
      log('P2P network connection initiated');
    } catch (e) {
      log('Error connecting to server: $e');
      connectionStatus.value = 'Connection failed';

      Get.snackbar(
        'Connection Error',
        'Failed to start P2P network: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.red,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Disconnect from server
  void disconnectFromServer() {
    try {
      log('Disconnecting from P2P network...');
      _chatRepository.disconnect();
      onlineUsers.clear();
      connectionStatus.value = 'Disconnected';
    } catch (e) {
      log('Error disconnecting: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || currentUser.value == null) return;

    try {
      final message = ChatMessage(
        id: _uuid.v4(),
        senderId: currentUser.value!.id,
        senderName: currentUser.value!.name,
        content: content.trim(),
        timestamp: DateTime.now(),
        type: MessageType.text,
        isFromCurrentUser: true,
        status: MessageStatus.sending,
      );

      // Add to local list immediately
      messages.add(message);
      _sortMessages();

      // Send through repository
      await _chatRepository.sendMessage(message);

      // Update status to sent
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index].status = MessageStatus.sent;
        messages.refresh();
      }

      log('Message sent: ${message.content}');
    } catch (e) {
      log('Error sending message: $e');

      // Update status to failed
      final failedMessage = messages.lastWhere((m) => m.content == content.trim());
      failedMessage.status = MessageStatus.failed;
      messages.refresh();

      Get.snackbar(
        'Send Failed',
        'Failed to send message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.2),
        colorText: Colors.orange,
      );
    }
  }

  /// Set current user
  Future<void> setCurrentUser(User user) async {
    try {
      currentUser.value = user;
      await _chatRepository.saveCurrentUser(user);
      log('Current user set: ${user.name}');
    } catch (e) {
      log('Error setting current user: $e');
      rethrow;
    }
  }

  /// Create and set a new user
  Future<void> createUser(String name) async {
    try {
      if (name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      final user = User(id: _uuid.v4(), name: name.trim(), isOnline: true, lastSeen: DateTime.now());

      await setCurrentUser(user);
      log('User created: ${user.name} (${user.id})');
    } catch (e) {
      log('Error creating user: $e');
      rethrow;
    }
  }

  /// Sort messages by timestamp
  void _sortMessages() {
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    try {
      await _chatRepository.clearAllMessages();
      messages.clear();
      log('All messages cleared');
    } catch (e) {
      log('Error clearing messages: $e');
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepository.deleteMessage(messageId);
      messages.removeWhere((m) => m.id == messageId);
      log('Message deleted: $messageId');
    } catch (e) {
      log('Error deleting message: $e');
    }
  }

  /// Get online users count
  int get onlineUsersCount => onlineUsers.length;

  /// Check if user is online
  bool isUserOnline(String userId) {
    return onlineUsers.any((user) => user.id == userId);
  }

  /// Refresh user discovery
  void refreshUserDiscovery() {
    if (isConnected.value) {
      _chatRepository.requestOnlineUsers();
    }
  }

  /// Force immediate super fast scanning
  void forceScan() {
    if (isConnected.value) {
      _chatRepository.forceScan();
      log('Force scanning triggered for immediate device discovery');
    }
  }

  /// Get user by ID
  User? getUserById(String userId) {
    return onlineUsers.firstWhereOrNull((user) => user.id == userId);
  }

  /// Update current user's name
  void updateUserName(String newName) {
    if (currentUser.value != null) {
      final updatedUser = User(
        id: currentUser.value!.id,
        name: newName,
        avatar: currentUser.value!.avatar,
        isOnline: currentUser.value!.isOnline,
        lastSeen: currentUser.value!.lastSeen,
      );
      currentUser.value = updatedUser;
      _chatRepository.updateCurrentUser(updatedUser);
    }
  }

  /// Update current user's avatar
  void updateUserAvatar(String newAvatar) {
    if (currentUser.value != null) {
      final updatedUser = User(
        id: currentUser.value!.id,
        name: currentUser.value!.name,
        avatar: newAvatar,
        isOnline: currentUser.value!.isOnline,
        lastSeen: currentUser.value!.lastSeen,
      );
      currentUser.value = updatedUser;
      _chatRepository.updateCurrentUser(updatedUser);
    }
  }

  /// Get network information
  Map<String, dynamic> getNetworkInfo() {
    final baseInfo = {
      'isConnected': isConnected.value,
      'userCount': onlineUsersCount,
      'currentUser': currentUser.value?.toJson(),
      'localIP': _chatRepository.isConnected ? 'Connected' : 'Disconnected',
      'protocol': 'UDP P2P',
      'discoveryPort': 8888,
      'messagePort': 8889,
    };

    // Add scanning information if available
    try {
      final scanningInfo = _chatRepository.getScanningInfo();
      baseInfo.addAll(scanningInfo);
    } catch (e) {
      log('Error getting scanning info: $e');
    }

    return baseInfo;
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    _messageSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _onlineUsersSubscription?.cancel();
    _connectionSubscription?.cancel();

    // Disconnect and dispose repository
    _chatRepository.dispose();

    super.onClose();
  }
}
