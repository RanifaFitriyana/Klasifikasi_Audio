import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/upload_audio_controller.dart';

class UploadAudioView extends GetView<UploadAudioController> {
  const UploadAudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio Classification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audio_file, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Obx(() => Text(controller.selectedFileName.value, style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 32),
              Obx(() => Text(controller.predictedLabel.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              Obx(() => controller.confidence.value > 0
                  ? Column(
                children: [
                  Text('Confidence: ${(controller.confidence.value * 100).toStringAsFixed(1)}%'),
                  LinearProgressIndicator(value: controller.confidence.value, color: Colors.deepPurple),
                ],
              )
                  : const SizedBox.shrink()),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: controller.pickAndClassifyFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Pilih Audio (.wav)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}