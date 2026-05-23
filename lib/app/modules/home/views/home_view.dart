import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Classification')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.UPLOAD_AUDIO),
              child: const Text('Klasifikasi dari Upload Audio'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.REALTIME_AUDIO),
              child: const Text('Klasifikasi Audio Realtime'),
            ),
          ],
        ),
      ),
    );
  }
}