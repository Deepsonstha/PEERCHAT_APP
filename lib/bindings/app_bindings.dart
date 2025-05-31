import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../data/datasources/local_storage_service.dart';
import '../data/datasources/p2p_network_service.dart';
import '../data/repositories/chat_repository.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize services
    Get.lazyPut<LocalStorageService>(() => LocalStorageService(), fenix: true);
    Get.lazyPut<P2PNetworkService>(() => P2PNetworkService(), fenix: true);

    // Initialize repository
    Get.lazyPut<ChatRepository>(() => ChatRepository(Get.find<LocalStorageService>(), Get.find<P2PNetworkService>()), fenix: true);

    // Initialize controllers
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
  }
}
