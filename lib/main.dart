import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bindings/app_bindings.dart';
import 'controllers/chat_controller.dart';
import 'data/models/chat_message.dart';
import 'data/models/user.dart';
import 'screens/all_users_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/private_chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
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

    print('Hive initialized successfully');
  } catch (e) {
    print('Error initializing Hive: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PeerChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: ThemeMode.system,
      initialBinding: AppBindings(),
      home: const AppInitializer(),
      getPages: [
        GetPage(name: '/', page: () => const AppInitializer(), binding: AppBindings()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/group-chat', page: () => const GroupChatScreen()),
        GetPage(name: '/private-chat', page: () => PrivateChatScreen(user: Get.arguments as User)),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(
          name: '/all-users',
          page:
              () => AllUsersScreen(users: (Get.arguments as Map)['users'] as List<User>, currentUser: (Get.arguments as Map)['currentUser'] as User?),
        ),
      ],
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for GetX bindings to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the chat controller
      final chatController = Get.find<ChatController>();

      // Wait for controller initialization
      await chatController.initializeIfNeeded();

      // Check if user exists
      if (chatController.currentUser.value == null) {
        // Navigate to welcome screen for first-time setup
        Get.offNamed('/welcome');
      } else {
        // Navigate to home screen
        Get.offNamed('/home');
      }
    } catch (e) {
      // Navigate to welcome screen as fallback
      Get.offNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: Icon(Icons.chat, size: 50, color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'PeerChat',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text('Peer-to-Peer Chat', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Initializing...', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
