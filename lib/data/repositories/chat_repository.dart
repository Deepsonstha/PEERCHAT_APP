import 'dart:async';
import 'dart:developer';

import '../datasources/local_storage_service.dart';
import '../datasources/p2p_network_service.dart';
import '../models/chat_message.dart';
import '../models/user.dart';

class ChatRepository {
  final LocalStorageService _localStorageService;
  final P2PNetworkService _networkService;

  ChatRepository(this._localStorageService, this._networkService);

  // Streams from network service
  Stream<ChatMessage> get messageStream => _networkService.messageStream;
  Stream<User> get userJoinedStream => _networkService.userJoinedStream;
  Stream<User> get userLeftStream => _networkService.userLeftStream;
  Stream<List<User>> get onlineUsersStream => _networkService.onlineUsersStream;
  Stream<bool> get connectionStream => _networkService.connectionStream;

  bool get isConnected => _networkService.isConnected;

  /// Initialize the repository
  Future<void> init() async {
    try {
      log('Initializing chat repository...');
      await _localStorageService.init();
      log('Chat repository initialized');
    } catch (e) {
      log('Error initializing chat repository: $e');
      rethrow;
    }
  }

  /// Connect to P2P network
  Future<void> connect({String? serverUrl, User? currentUser}) async {
    try {
      if (currentUser == null) {
        throw Exception('Current user is required to connect');
      }

      log('Connecting to P2P network...');
      await _networkService.start(currentUser);
      log('Connected to P2P network');
    } catch (e) {
      log('Error connecting to P2P network: $e');
      rethrow;
    }
  }

  /// Disconnect from P2P network
  void disconnect() {
    try {
      log('Disconnecting from P2P network...');
      _networkService.stop();
      log('Disconnected from P2P network');
    } catch (e) {
      log('Error disconnecting from P2P network: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      // Save to local storage first
      await _localStorageService.saveMessage(message);

      // Send via P2P network
      await _networkService.sendMessage(message);

      log('Message sent and saved: ${message.content}');
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  /// Save received message
  Future<void> saveReceivedMessage(ChatMessage message) async {
    try {
      await _localStorageService.saveMessage(message);
      log('Received message saved: ${message.content}');
    } catch (e) {
      log('Error saving received message: $e');
    }
  }

  /// Get all messages from local storage
  List<ChatMessage> getAllMessages() {
    try {
      return _localStorageService.getAllMessages();
    } catch (e) {
      log('Error getting all messages: $e');
      return [];
    }
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    try {
      await _localStorageService.clearAllMessages();
      log('All messages cleared');
    } catch (e) {
      log('Error clearing all messages: $e');
      rethrow;
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _localStorageService.deleteMessage(messageId);
      log('Message deleted: $messageId');
    } catch (e) {
      log('Error deleting message: $e');
      rethrow;
    }
  }

  /// Save current user
  Future<void> saveCurrentUser(User user) async {
    try {
      await _localStorageService.saveCurrentUser(user);
      log('Current user saved: ${user.name}');
    } catch (e) {
      log('Error saving current user: $e');
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    try {
      return _localStorageService.getCurrentUser();
    } catch (e) {
      log('Error getting current user: $e');
      return null;
    }
  }

  /// Update current user
  Future<void> updateCurrentUser(User user) async {
    try {
      await _localStorageService.saveCurrentUser(user);

      // Also update the network service's current user and broadcast changes
      _networkService.updateCurrentUser(user);

      log('Current user updated: ${user.name}');
    } catch (e) {
      log('Error updating current user: $e');
      rethrow;
    }
  }

  /// Request online users
  void requestOnlineUsers() {
    try {
      _networkService.requestOnlineUsers();
    } catch (e) {
      log('Error requesting online users: $e');
    }
  }

  /// Force immediate super fast scanning
  void forceScan() {
    try {
      _networkService.forceScan();
      log('Force scanning triggered');
    } catch (e) {
      log('Error triggering force scan: $e');
    }
  }

  /// Get scanning status information
  Map<String, dynamic> getScanningInfo() {
    try {
      return _networkService.getScanningInfo();
    } catch (e) {
      log('Error getting scanning info: $e');
      return {'scanningMode': 'unknown', 'error': e.toString()};
    }
  }

  /// Get network information
  Map<String, dynamic> getNetworkInfo() {
    try {
      return _networkService.getNetworkInfo();
    } catch (e) {
      log('Error getting network info: $e');
      return {'isConnected': false, 'error': e.toString()};
    }
  }

  /// Get local IP address
  Future<String?> getLocalIPAddress() async {
    try {
      return await _networkService.getLocalIPAddress();
    } catch (e) {
      log('Error getting local IP address: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      log('Disposing chat repository...');
      _networkService.dispose();
      _localStorageService.close();
      log('Chat repository disposed');
    } catch (e) {
      log('Error disposing chat repository: $e');
    }
  }
}
