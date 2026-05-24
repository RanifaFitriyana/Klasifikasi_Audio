import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/realtime_audio_controller.dart';

class RealtimeAudioView extends GetView<RealtimeAudioController> {
  const RealtimeAudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FC),
      appBar: AppBar(
        title: const Text(
          'Realtime Audio Classification',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),
              // Microphone circle visualizer
              Obx(() => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: controller.isRecording.value
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: controller.isRecording.value
                              ? Colors.red.withOpacity(0.2)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        controller.isRecording.value ? Icons.mic : Icons.mic_none,
                        size: 64,
                        color: controller.isRecording.value
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              // Subtitle
              Obx(() => Text(
                    controller.isRecording.value ? 'Listening...' : 'Ready to Record',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.isRecording.value
                          ? Colors.red.shade600
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
              const SizedBox(height: 8),
              // Big title label
              Obx(() => Text(
                    controller.predictedLabel.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  )),
              const Spacer(),
              // Probabilities Card
              Obx(() {
                if (controller.labelProbabilities.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.labelProbabilities.entries.map((entry) {
                        String label = entry.key;
                        double value = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${((value.isNaN || value.isInfinite ? 0.0 : value) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (value.isNaN || value.isInfinite) ? 0.0 : value,
                                  minHeight: 8,
                                  backgroundColor: Colors.deepPurple.shade50,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Start/Stop recording button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: controller.toggleRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 3,
                      ),
                      icon: Icon(controller.isRecording.value ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        controller.isRecording.value ? 'Stop Recording' : 'Start Recording',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}