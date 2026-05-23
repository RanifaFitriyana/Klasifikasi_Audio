import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/realtime_audio/bindings/realtime_audio_binding.dart';
import '../modules/realtime_audio/views/realtime_audio_view.dart';
import '../modules/upload_audio/bindings/upload_audio_binding.dart';
import '../modules/upload_audio/views/upload_audio_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.UPLOAD_AUDIO,
      page: () => const UploadAudioView(),
      binding: UploadAudioBinding(),
    ),
    GetPage(
      name: _Paths.REALTIME_AUDIO,
      page: () => const RealtimeAudioView(),
      binding: RealtimeAudioBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}
