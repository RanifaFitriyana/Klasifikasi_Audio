import 'package:get/get.dart';

import '../controllers/upload_audio_controller.dart';

class UploadAudioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadAudioController>(
      () => UploadAudioController(),
    );
  }
}
