import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../models/user.dart';

class LocalStorageService {
  static const String _messagesBoxName = 'messages';
  static const String _usersBoxName = 'users';
  static const String _settingsBoxName = 'settings';

  Box<ChatMessage>? _messagesBox;
  Box<User>? _usersBox;
  Box? _settingsBox;

  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('Initializing LocalStorageService...');

      // Check if boxes are already open, if not open them
      if (!Hive.isBoxOpen(_messagesBoxName)) {
        _messagesBox = await Hive.openBox<ChatMessage>(_messagesBoxName);
      } else {
        _messagesBox = Hive.box<ChatMessage>(_messagesBoxName);
      }

      if (!Hive.isBoxOpen(_usersBoxName)) {
        _usersBox = await Hive.openBox<User>(_usersBoxName);
      } else {
        _usersBox = Hive.box<User>(_usersBoxName);
      }

      if (!Hive.isBoxOpen(_settingsBoxName)) {
        _settingsBox = await Hive.openBox(_settingsBoxName);
      } else {
        _settingsBox = Hive.box(_settingsBoxName);
      }

      _isInitialized = true;
      print('LocalStorageService initialized successfully');
    } catch (e) {
      print('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  /// Messages operations
  Future<void> saveMessage(ChatMessage message) async {
    if (!_isInitialized) await init();
    await _messagesBox!.put(message.id, message);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    if (!_isInitialized) await init();
    final Map<String, ChatMessage> messageMap = {for (var message in messages) message.id: message};
    await _messagesBox!.putAll(messageMap);
  }

  List<ChatMessage> getAllMessages() {
    if (!_isInitialized || _messagesBox == null) return [];
    try {
      return _messagesBox!.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      print('Error getting all messages: $e');
      return [];
    }
  }

  ChatMessage? getMessage(String id) {
    if (!_isInitialized || _messagesBox == null) return null;
    try {
      return _messagesBox!.get(id);
    } catch (e) {
      print('Error getting message: $e');
      return null;
    }
  }

  Future<void> deleteMessage(String id) async {
    if (!_isInitialized) await init();
    await _messagesBox!.delete(id);
  }

  Future<void> clearAllMessages() async {
    if (!_isInitialized) await init();
    await _messagesBox!.clear();
  }

  /// Users operations
  Future<void> saveUser(User user) async {
    if (!_isInitialized) await init();
    await _usersBox!.put(user.id, user);
  }

  List<User> getAllUsers() {
    if (!_isInitialized || _usersBox == null) return [];
    try {
      return _usersBox!.values.toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  User? getUser(String id) {
    if (!_isInitialized || _usersBox == null) return null;
    try {
      return _usersBox!.get(id);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> deleteUser(String id) async {
    if (!_isInitialized) await init();
    await _usersBox!.delete(id);
  }

  /// Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    if (!_isInitialized) await init();
    await _settingsBox!.put(key, value);
  }

  T? getSetting<T>(String key) {
    if (!_isInitialized || _settingsBox == null) return null;
    try {
      final value = _settingsBox!.get(key);
      if (value == null) return null;

      // Safe type casting with null checks
      if (T == bool) {
        if (value is bool) return value as T;
        if (value is String) {
          return (value.toLowerCase() == 'true') as T;
        }
        return null;
      }

      return value as T?;
    } catch (e) {
      print('Error getting setting $key: $e');
      return null;
    }
  }

  Future<void> deleteSetting(String key) async {
    if (!_isInitialized) await init();
    await _settingsBox!.delete(key);
  }

  /// Current user operations
  Future<void> saveCurrentUser(User user) async {
    if (!_isInitialized) await init();
    await saveSetting('current_user_id', user.id);
    await saveUser(user);
  }

  User? getCurrentUser() {
    if (!_isInitialized) return null;
    try {
      final userId = getSetting<String>('current_user_id');
      if (userId != null) {
        return getUser(userId);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Watch for changes
  Stream<BoxEvent> watchMessages() {
    if (!_isInitialized || _messagesBox == null) return const Stream.empty();
    return _messagesBox!.watch();
  }

  Stream<BoxEvent> watchUsers() {
    if (!_isInitialized || _usersBox == null) return const Stream.empty();
    return _usersBox!.watch();
  }

  /// Close all boxes
  Future<void> close() async {
    if (!_isInitialized) return;
    await _messagesBox?.close();
    await _usersBox?.close();
    await _settingsBox?.close();
    _messagesBox = null;
    _usersBox = null;
    _settingsBox = null;
    _isInitialized = false;
  }
}
