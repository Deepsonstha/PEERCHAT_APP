import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import '../models/chat_message.dart';
import '../models/user.dart';

/// Peer-to-peer network service for local network communication
/// No backend server required - works fully offline on same WiFi network
class P2PNetworkService {
  static const int discoveryPort = 8888;
  static const int messagePort = 8889;
  static const String broadcastAddress = '255.255.255.255';

  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _messageSocket;
  Timer? _discoveryTimer;
  Timer? _heartbeatTimer;

  User? _currentUser;
  final Map<String, User> _discoveredUsers = {};
  final Map<String, DateTime> _lastSeen = {};

  // Stream controllers
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<User> _userJoinedController = StreamController<User>.broadcast();
  final StreamController<User> _userLeftController = StreamController<User>.broadcast();
  final StreamController<List<User>> _onlineUsersController = StreamController<List<User>>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  // Streams
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<User> get userJoinedStream => _userJoinedController.stream;
  Stream<User> get userLeftStream => _userLeftController.stream;
  Stream<List<User>> get onlineUsersStream => _onlineUsersController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _discoverySocket != null && _messageSocket != null;

  /// Initialize the P2P network service
  Future<void> init() async {
    try {
      log('Initializing P2P network service...');

      // Create discovery socket for finding peers
      _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _discoverySocket!.broadcastEnabled = true;
      _discoverySocket!.listen(_handleDiscoveryData);

      // Create message socket for sending/receiving messages
      _messageSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, messagePort);
      _messageSocket!.listen(_handleMessageData);

      log('P2P sockets bound successfully');
      log('Discovery socket: ${_discoverySocket!.address.address}:${_discoverySocket!.port}');
      log('Message socket: ${_messageSocket!.address.address}:${_messageSocket!.port}');

      _connectionController.add(true);
    } catch (e) {
      log('Error initializing P2P network: $e');
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Start the P2P network with current user
  Future<void> start(User currentUser) async {
    try {
      _currentUser = currentUser;

      if (!isConnected) {
        await init();
      }

      // Start periodic discovery broadcasts
      _startDiscovery();

      // Start heartbeat to maintain presence
      _startHeartbeat();

      log('P2P network started for user: ${currentUser.name}');
    } catch (e) {
      log('Error starting P2P network: $e');
      rethrow;
    }
  }

  /// Stop the P2P network
  void stop() {
    try {
      log('Stopping P2P network...');

      // Send goodbye message
      if (_currentUser != null) {
        _broadcastUserLeft(_currentUser!);
      }

      // Stop timers
      _discoveryTimer?.cancel();
      _heartbeatTimer?.cancel();

      // Close sockets
      _discoverySocket?.close();
      _messageSocket?.close();

      // Clear state
      _discoverySocket = null;
      _messageSocket = null;
      _currentUser = null;
      _discoveredUsers.clear();
      _lastSeen.clear();

      _connectionController.add(false);
      log('P2P network stopped');
    } catch (e) {
      log('Error stopping P2P network: $e');
    }
  }

  /// Send a chat message
  Future<void> sendMessage(ChatMessage message) async {
    if (!isConnected || _currentUser == null) {
      throw Exception('P2P network not connected');
    }

    try {
      final data = {
        'type': 'message',
        'message': message.toJson(),
        'sender': _currentUser!.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);

      // Send to all discovered users
      for (final user in _discoveredUsers.values) {
        if (user.id != _currentUser!.id) {
          await _sendToUser(bytes, user);
        }
      }

      log('Message sent: ${message.content}');
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  /// Request online users
  void requestOnlineUsers() {
    if (!isConnected || _currentUser == null) return;

    try {
      final data = {'type': 'discovery', 'user': _currentUser!.toJson(), 'timestamp': DateTime.now().millisecondsSinceEpoch};

      _broadcastData(data);
      _cleanupOfflineUsers();
      _onlineUsersController.add(_discoveredUsers.values.toList());
    } catch (e) {
      log('Error requesting online users: $e');
    }
  }

  /// Update current user and broadcast changes immediately
  void updateCurrentUser(User updatedUser) {
    if (!isConnected) return;

    try {
      _currentUser = updatedUser;

      // Broadcast updated user info immediately
      final data = {'type': 'heartbeat', 'user': _currentUser!.toJson(), 'timestamp': DateTime.now().millisecondsSinceEpoch};
      _broadcastData(data);

      log('User updated and broadcasted: ${updatedUser.name}');
    } catch (e) {
      log('Error updating current user: $e');
    }
  }

  /// Start periodic discovery broadcasts
  void _startDiscovery() {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentUser != null) {
        requestOnlineUsers();
      }
    });
  }

  /// Start heartbeat to maintain presence
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentUser != null) {
        final data = {'type': 'heartbeat', 'user': _currentUser!.toJson(), 'timestamp': DateTime.now().millisecondsSinceEpoch};
        _broadcastData(data);
      }
    });
  }

  /// Handle discovery socket data
  void _handleDiscoveryData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      try {
        final datagram = _discoverySocket!.receive();
        if (datagram != null) {
          final data = utf8.decode(datagram.data);
          final json = jsonDecode(data) as Map<String, dynamic>;

          _processDiscoveryMessage(json, datagram.address);
        }
      } catch (e) {
        log('Error handling discovery data: $e');
      }
    }
  }

  /// Handle message socket data
  void _handleMessageData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      try {
        final datagram = _messageSocket!.receive();
        if (datagram != null) {
          final data = utf8.decode(datagram.data);
          final json = jsonDecode(data) as Map<String, dynamic>;

          _processMessage(json, datagram.address);
        }
      } catch (e) {
        log('Error handling message data: $e');
      }
    }
  }

  /// Process discovery message
  void _processDiscoveryMessage(Map<String, dynamic> data, InternetAddress address) {
    try {
      final type = data['type'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (userData == null) return;

      final user = User.fromJson(userData);

      // Don't process our own messages
      if (_currentUser != null && user.id == _currentUser!.id) return;

      // Update user's IP address for direct communication
      user.ipAddress = address.address;

      switch (type) {
        case 'discovery':
          _handleUserDiscovered(user);
          break;
        case 'heartbeat':
          _handleUserHeartbeat(user);
          break;
        case 'user_left':
          _handleUserLeftMessage(user);
          break;
      }
    } catch (e) {
      log('Error processing discovery message: $e');
    }
  }

  /// Process chat message
  void _processMessage(Map<String, dynamic> data, InternetAddress address) {
    try {
      final type = data['type'] as String?;

      if (type == 'message') {
        final messageData = data['message'] as Map<String, dynamic>?;
        final senderData = data['sender'] as Map<String, dynamic>?;

        if (messageData != null && senderData != null) {
          final message = ChatMessage.fromJson(messageData);
          final sender = User.fromJson(senderData);

          // Don't process our own messages
          if (_currentUser != null && sender.id == _currentUser!.id) return;

          // Update sender's IP
          sender.ipAddress = address.address;
          _handleUserDiscovered(sender);

          // Emit message
          _messageController.add(message);
          log('Received message from ${sender.name}: ${message.content}');
        }
      }
    } catch (e) {
      log('Error processing message: $e');
    }
  }

  /// Handle user discovered
  void _handleUserDiscovered(User user) {
    final wasNew = !_discoveredUsers.containsKey(user.id);

    _discoveredUsers[user.id] = user;
    _lastSeen[user.id] = DateTime.now();

    if (wasNew) {
      _userJoinedController.add(user);
      log('User discovered: ${user.name} (${user.ipAddress})');
    }

    _onlineUsersController.add(_discoveredUsers.values.toList());
  }

  /// Handle user heartbeat
  void _handleUserHeartbeat(User user) {
    if (_discoveredUsers.containsKey(user.id)) {
      _lastSeen[user.id] = DateTime.now();
      _discoveredUsers[user.id] = user;
    } else {
      _handleUserDiscovered(user);
    }
  }

  /// Handle user left message
  void _handleUserLeftMessage(User user) {
    if (_discoveredUsers.containsKey(user.id)) {
      _discoveredUsers.remove(user.id);
      _lastSeen.remove(user.id);
      _userLeftController.add(user);
      _onlineUsersController.add(_discoveredUsers.values.toList());
      log('User left: ${user.name}');
    }
  }

  /// Broadcast data to discovery port
  void _broadcastData(Map<String, dynamic> data) {
    try {
      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);

      _discoverySocket?.send(bytes, InternetAddress(broadcastAddress), discoveryPort);
    } catch (e) {
      log('Error broadcasting data: $e');
    }
  }

  /// Send data to specific user
  Future<void> _sendToUser(Uint8List data, User user) async {
    try {
      if (user.ipAddress != null) {
        _messageSocket?.send(data, InternetAddress(user.ipAddress!), messagePort);
      }
    } catch (e) {
      log('Error sending to user ${user.name}: $e');
    }
  }

  /// Broadcast user left message
  void _broadcastUserLeft(User user) {
    final data = {'type': 'user_left', 'user': user.toJson(), 'timestamp': DateTime.now().millisecondsSinceEpoch};
    _broadcastData(data);
  }

  /// Clean up offline users
  void _cleanupOfflineUsers() {
    final now = DateTime.now();
    final offlineThreshold = const Duration(seconds: 30);

    final offlineUsers = <String>[];

    for (final entry in _lastSeen.entries) {
      if (now.difference(entry.value) > offlineThreshold) {
        offlineUsers.add(entry.key);
      }
    }

    for (final userId in offlineUsers) {
      final user = _discoveredUsers.remove(userId);
      _lastSeen.remove(userId);

      if (user != null) {
        _userLeftController.add(user);
        log('User timed out: ${user.name}');
      }
    }

    if (offlineUsers.isNotEmpty) {
      _onlineUsersController.add(_discoveredUsers.values.toList());
    }
  }

  /// Get local IP address
  Future<String?> getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            // Prefer WiFi interfaces
            if (interface.name.toLowerCase().contains('wlan') ||
                interface.name.toLowerCase().contains('wifi') ||
                interface.name.toLowerCase().contains('en0')) {
              return address.address;
            }
          }
        }
      }

      // Fallback to any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      log('Error getting local IP: $e');
    }

    return null;
  }

  /// Get network information
  Map<String, dynamic> getNetworkInfo() {
    return {
      'isConnected': isConnected,
      'discoveryPort': discoveryPort,
      'messagePort': messagePort,
      'currentUser': _currentUser?.toJson(),
      'discoveredUsers': _discoveredUsers.length,
      'localIP': _discoverySocket?.address.address,
    };
  }

  /// Dispose resources
  void dispose() {
    try {
      stop();

      _messageController.close();
      _userJoinedController.close();
      _userLeftController.close();
      _onlineUsersController.close();
      _connectionController.close();

      log('P2P network service disposed');
    } catch (e) {
      log('Error disposing P2P network service: $e');
    }
  }
}
