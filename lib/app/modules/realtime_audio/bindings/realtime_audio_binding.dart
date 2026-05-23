import 'package:get/get.dart';

import '../controllers/realtime_audio_controller.dart';

class RealtimeAudioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RealtimeAudioController>(
      () => RealtimeAudioController(),
    );
  }
}