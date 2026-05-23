import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/realtime_audio_controller.dart';

class RealtimeAudioView
    extends GetView<RealtimeAudioController> {
  const RealtimeAudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Realtime Audio Classification',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                // =================================
                // ICON
                // =================================

                AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 300,
                  ),
                  child: Icon(
                    controller
                            .isRecording.value
                        ? Icons.mic
                        : Icons.mic_none,
                    size: 120,
                    color: controller
                            .isRecording.value
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                // =================================
                // LABEL
                // =================================

                Text(
                  controller
                      .predictedLabel.value,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // =================================
                // CONFIDENCE
                // =================================

                if (controller
                        .confidence.value >
                    0)
                  Column(
                    children: [
                      Text(
                        "Confidence: ${(controller.confidence.value * 100).toStringAsFixed(1)}%",
                        style:
                            const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      LinearProgressIndicator(
                        value: controller
                            .confidence.value,
                        minHeight: 10,
                      ),
                    ],
                  ),

                const SizedBox(height: 50),

                // =================================
                // BUTTON
                // =================================

                ElevatedButton.icon(
                  onPressed: () {
                    controller
                        .toggleRecording();
                  },
                  icon: Icon(
                    controller
                            .isRecording.value
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    controller
                            .isRecording.value
                        ? "Stop Recording"
                        : "Start Recording",
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
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