import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import '../models/chat_message.dart';
import '../models/user.dart';

/// Peer-to-peer network service for local network communication
/// No backend server required - works fully offline on same WiFi network
/// OPTIMIZED FOR SUPER FAST DEVICE SCANNING
class P2PNetworkService {
  static const int discoveryPort = 8888;
  static const int messagePort = 8889;
  static const String broadcastAddress = '255.255.255.255';

  // FAST SCANNING CONFIGURATION
  static const Duration fastDiscoveryInterval = Duration(milliseconds: 500); // Super fast scanning
  static const Duration normalDiscoveryInterval = Duration(seconds: 2); // Normal scanning
  static const Duration burstDiscoveryInterval = Duration(milliseconds: 100); // Burst scanning
  static const Duration adaptiveSlowdown = Duration(seconds: 10); // When to slow down
  static const int burstCount = 10; // Number of burst scans
  static const int maxParallelScans = 3; // Parallel scanning attempts

  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _messageSocket;
  Timer? _discoveryTimer;
  Timer? _heartbeatTimer;
  Timer? _burstTimer;

  User? _currentUser;
  final Map<String, User> _discoveredUsers = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, int> _discoveryAttempts = {}; // Track discovery attempts

  // Fast scanning state
  bool _isFastScanning = false;
  bool _isBurstScanning = false;
  DateTime? _lastNewUserFound;
  int _burstCounter = 0;

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
      log('Initializing P2P network service with SUPER FAST scanning...');

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

      // Start with BURST SCANNING for immediate discovery
      _startBurstScanning();

      // Start fast discovery
      _startFastDiscovery();

      // Start heartbeat to maintain presence
      _startHeartbeat();

      log('P2P network started for user: ${currentUser.name} with SUPER FAST scanning');
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
      _burstTimer?.cancel();

      // Close sockets
      _discoverySocket?.close();
      _messageSocket?.close();

      // Clear state
      _discoverySocket = null;
      _messageSocket = null;
      _currentUser = null;
      _discoveredUsers.clear();
      _lastSeen.clear();
      _discoveryAttempts.clear();
      _isFastScanning = false;
      _isBurstScanning = false;
      _lastNewUserFound = null;
      _burstCounter = 0;

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

  /// Request online users with SUPER FAST scanning
  void requestOnlineUsers() {
    if (!isConnected || _currentUser == null) return;

    try {
      final data = {
        'type': 'discovery',
        'user': _currentUser!.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'fastScan': _isFastScanning || _isBurstScanning, // Indicate fast scanning mode
      };

      // PARALLEL SCANNING: Send multiple broadcasts for better coverage
      for (int i = 0; i < maxParallelScans; i++) {
        _broadcastData(data);
      }

      _cleanupOfflineUsers();
      _onlineUsersController.add(_discoveredUsers.values.toList());

      log('Fast discovery broadcast sent (parallel: $maxParallelScans)');
    } catch (e) {
      log('Error requesting online users: $e');
    }
  }

  /// Update current user and broadcast changes immediately
  void updateCurrentUser(User updatedUser) {
    if (!isConnected) return;

    try {
      _currentUser = updatedUser;

      // Broadcast updated user info immediately with parallel sends
      final data = {
        'type': 'heartbeat',
        'user': _currentUser!.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'fastScan': _isFastScanning || _isBurstScanning,
      };

      // Send multiple times for reliability
      for (int i = 0; i < maxParallelScans; i++) {
        _broadcastData(data);
      }

      log('User updated and broadcasted: ${updatedUser.name}');
    } catch (e) {
      log('Error updating current user: $e');
    }
  }

  /// Start BURST SCANNING for immediate device discovery
  void _startBurstScanning() {
    _isBurstScanning = true;
    _burstCounter = 0;

    log('Starting BURST scanning for super fast discovery...');

    _burstTimer = Timer.periodic(burstDiscoveryInterval, (timer) {
      if (_currentUser != null && _burstCounter < burstCount) {
        requestOnlineUsers();
        _burstCounter++;
        log('Burst scan #$_burstCounter');
      } else {
        // Stop burst scanning and switch to fast scanning
        timer.cancel();
        _isBurstScanning = false;
        log('Burst scanning completed, switching to fast scanning');
      }
    });
  }

  /// Start FAST DISCOVERY with adaptive intervals
  void _startFastDiscovery() {
    _isFastScanning = true;

    _discoveryTimer = Timer.periodic(fastDiscoveryInterval, (timer) {
      if (_currentUser != null) {
        requestOnlineUsers();

        // ADAPTIVE SCANNING: Slow down if no new users found recently
        if (_lastNewUserFound != null) {
          final timeSinceLastUser = DateTime.now().difference(_lastNewUserFound!);
          if (timeSinceLastUser > adaptiveSlowdown) {
            // Switch to normal scanning speed
            _switchToNormalScanning();
          }
        }
      }
    });
  }

  /// Switch to normal scanning speed to save resources
  void _switchToNormalScanning() {
    if (!_isFastScanning) return;

    _isFastScanning = false;
    _discoveryTimer?.cancel();

    log('Switching to normal scanning speed');

    _discoveryTimer = Timer.periodic(normalDiscoveryInterval, (timer) {
      if (_currentUser != null) {
        requestOnlineUsers();
      }
    });
  }

  /// Switch back to fast scanning when activity detected
  void _switchToFastScanning() {
    if (_isFastScanning) return;

    _isFastScanning = true;
    _discoveryTimer?.cancel();

    log('Switching to fast scanning speed');

    _discoveryTimer = Timer.periodic(fastDiscoveryInterval, (timer) {
      if (_currentUser != null) {
        requestOnlineUsers();

        // Check if we should slow down again
        if (_lastNewUserFound != null) {
          final timeSinceLastUser = DateTime.now().difference(_lastNewUserFound!);
          if (timeSinceLastUser > adaptiveSlowdown) {
            _switchToNormalScanning();
          }
        }
      }
    });
  }

  /// Start heartbeat with faster intervals
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentUser != null) {
        final data = {
          'type': 'heartbeat',
          'user': _currentUser!.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'fastScan': _isFastScanning || _isBurstScanning,
        };
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

  /// Process discovery message with IMMEDIATE RESPONSE
  void _processDiscoveryMessage(Map<String, dynamic> data, InternetAddress address) {
    try {
      final type = data['type'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;
      final isFastScan = data['fastScan'] as bool? ?? false;

      if (userData == null) return;

      final user = User.fromJson(userData);

      // Don't process our own messages
      if (_currentUser != null && user.id == _currentUser!.id) return;

      // Update user's IP address for direct communication
      user.ipAddress = address.address;

      switch (type) {
        case 'discovery':
          _handleUserDiscovered(user);

          // IMMEDIATE RESPONSE: Reply immediately to discovery requests
          if (_currentUser != null) {
            final responseData = {
              'type': 'discovery_response',
              'user': _currentUser!.toJson(),
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'fastScan': _isFastScanning || _isBurstScanning,
            };
            _broadcastData(responseData);
            log('Sent immediate discovery response to ${user.name}');
          }

          // If sender is fast scanning, switch to fast scanning too
          if (isFastScan && !_isFastScanning) {
            _switchToFastScanning();
          }
          break;

        case 'discovery_response':
          _handleUserDiscovered(user);
          log('Received discovery response from ${user.name}');
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

  /// Handle user discovered with fast scanning optimization
  void _handleUserDiscovered(User user) {
    final wasNew = !_discoveredUsers.containsKey(user.id);

    _discoveredUsers[user.id] = user;
    _lastSeen[user.id] = DateTime.now();

    if (wasNew) {
      _userJoinedController.add(user);
      _lastNewUserFound = DateTime.now(); // Track when we found a new user

      // Switch to fast scanning when new users are found
      if (!_isFastScanning && !_isBurstScanning) {
        _switchToFastScanning();
      }

      log('User discovered: ${user.name} (${user.ipAddress}) - FAST SCAN ACTIVE');
    }

    _onlineUsersController.add(_discoveredUsers.values.toList());
  }

  /// Handle user heartbeat with optimization
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

  /// Broadcast data to discovery port with optimization
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

  /// Clean up offline users with faster timeout for responsiveness
  void _cleanupOfflineUsers() {
    final now = DateTime.now();
    final offlineThreshold = const Duration(seconds: 15); // Faster cleanup

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

  /// Force immediate scan for super fast discovery
  void forceScan() {
    if (!isConnected || _currentUser == null) return;

    log('Force scanning for immediate device discovery...');

    // Send multiple immediate discovery requests
    for (int i = 0; i < maxParallelScans * 2; i++) {
      requestOnlineUsers();
    }

    // Switch to fast scanning mode
    if (!_isFastScanning) {
      _switchToFastScanning();
    }
  }

  /// Get scanning status information
  Map<String, dynamic> getScanningInfo() {
    return {
      'isFastScanning': _isFastScanning,
      'isBurstScanning': _isBurstScanning,
      'burstCounter': _burstCounter,
      'lastNewUserFound': _lastNewUserFound?.toIso8601String(),
      'discoveredUsers': _discoveredUsers.length,
      'scanningMode': _isBurstScanning ? 'burst' : (_isFastScanning ? 'fast' : 'normal'),
    };
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
