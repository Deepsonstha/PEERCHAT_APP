import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../models/user.dart';

class LocalStorageService {
  static const String _messagesBoxName = 'messages';
  static const String _usersBoxName = 'users';
  static const String _settingsBoxName = 'settings';

  late Box<ChatMessage> _messagesBox;
  late Box<User> _usersBox;
  late Box _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserAdapter());
    }

    // Open boxes
    _messagesBox = await Hive.openBox<ChatMessage>(_messagesBoxName);
    _usersBox = await Hive.openBox<User>(_usersBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Messages operations
  Future<void> saveMessage(ChatMessage message) async {
    await _messagesBox.put(message.id, message);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final Map<String, ChatMessage> messageMap = {for (var message in messages) message.id: message};
    await _messagesBox.putAll(messageMap);
  }

  List<ChatMessage> getAllMessages() {
    return _messagesBox.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  ChatMessage? getMessage(String id) {
    return _messagesBox.get(id);
  }

  Future<void> deleteMessage(String id) async {
    await _messagesBox.delete(id);
  }

  Future<void> clearAllMessages() async {
    await _messagesBox.clear();
  }

  /// Users operations
  Future<void> saveUser(User user) async {
    await _usersBox.put(user.id, user);
  }

  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  User? getUser(String id) {
    return _usersBox.get(id);
  }

  Future<void> deleteUser(String id) async {
    await _usersBox.delete(id);
  }

  /// Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key) {
    return _settingsBox.get(key) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  /// Current user operations
  Future<void> saveCurrentUser(User user) async {
    await saveSetting('current_user_id', user.id);
    await saveUser(user);
  }

  User? getCurrentUser() {
    final userId = getSetting<String>('current_user_id');
    if (userId != null) {
      return getUser(userId);
    }
    return null;
  }

  /// Watch for changes
  Stream<BoxEvent> watchMessages() {
    return _messagesBox.watch();
  }

  Stream<BoxEvent> watchUsers() {
    return _usersBox.watch();
  }

  /// Close all boxes
  Future<void> close() async {
    await _messagesBox.close();
    await _usersBox.close();
    await _settingsBox.close();
  }
}
