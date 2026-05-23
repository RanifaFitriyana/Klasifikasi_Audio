import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/upload_audio_controller.dart';

class UploadAudioView
    extends GetView<UploadAudioController> {
  const UploadAudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Audio"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.audio_file,
                  size: 100,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                Text(
                  controller.selectedFileName.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  controller.predictedLabel.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (controller.confidence.value > 0)
                  Column(
                    children: [
                      Text(
                        "Confidence: ${(controller.confidence.value * 100).toStringAsFixed(2)}%",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value:
                            controller.confidence.value,
                        minHeight: 10,
                      ),
                    ],
                  ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : controller
                                .pickAndClassifyFile,
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.upload),

                    label: Text(
                      controller.isLoading.value
                          ? "Processing..."
                          : "Pilih File WAV",
                    ),

                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}