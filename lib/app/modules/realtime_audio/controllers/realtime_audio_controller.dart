import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RealtimeAudioController extends GetxController {
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<Uint8List>? _audioStreamSubscription;

  Interpreter? _interpreter;

  List<String> _labels = [];

  final isRecording = false.obs;

  final predictedLabel = "Loading model...".obs;

  final confidence = 0.0.obs;

  static const int sampleRate = 16000;

  static const int expectedInputSize = 15600;

  List<int> audioBuffer = [];

  bool isInferencing = false;

  Timer? debounceTimer;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void onInit() {
    super.onInit();
    loadModelAndLabels();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void onClose() {
    stopRecording();

    _audioRecorder.dispose();

    _interpreter?.close();

    debounceTimer?.cancel();

    super.onClose();
  }

  // =========================================================
  // LOAD MODEL
  // =========================================================

  Future<void> loadModelAndLabels() async {
    try {
      // LOAD LABELS
      final labelData =
          await rootBundle.loadString('assets/ml/labels.txt');

      _labels = labelData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
        final parts = line.split(' ');

        if (parts.length > 1) {
          return parts.sublist(1).join(' ');
        }

        return line;
      }).toList();

      // LOAD MODEL
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/soundclassifier_with_metadata.tflite',
      );

      predictedLabel.value = "Ready to record";
    } catch (e) {
      predictedLabel.value = "Failed to load model";

      print("MODEL ERROR: $e");
    }
  }

  // =========================================================
  // TOGGLE RECORD
  // =========================================================

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  // =========================================================
  // START RECORD
  // =========================================================

  Future<void> startRecording() async {
    try {
      final micPermission =
          await Permission.microphone.request();

      if (!micPermission.isGranted) {
        predictedLabel.value =
            "Microphone permission denied";

        return;
      }

      if (!await _audioRecorder.hasPermission()) {
        predictedLabel.value =
            "Recorder permission denied";

        return;
      }

      final stream =
          await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );

      // RESET
      audioBuffer.clear();

      confidence.value = 0.0;

      predictedLabel.value = "Listening...";

      isRecording.value = true;

      // LISTEN AUDIO STREAM
      _audioStreamSubscription =
          stream.listen(
        processAudioData,
        onError: (e) {
          predictedLabel.value =
              "Stream Error";

          print("STREAM ERROR: $e");
        },
      );
    } catch (e) {
      predictedLabel.value =
          "Error starting record";

      print("START RECORD ERROR: $e");
    }
  }

  // =========================================================
  // STOP RECORD
  // =========================================================

  Future<void> stopRecording() async {
    try {
      await _audioStreamSubscription?.cancel();

      _audioStreamSubscription = null;

      await _audioRecorder.stop();

      debounceTimer?.cancel();

      isRecording.value = false;

      // JANGAN RESET HASIL
      // predictedLabel.value = "Ready to record";

      // confidence.value = 0.0;
    } catch (e) {
      print("STOP ERROR: $e");
    }
  }

  // =========================================================
  // PROCESS AUDIO
  // =========================================================

  void processAudioData(Uint8List data) {
    try {
      // PCM 16 BIT
      Int16List int16Data = data.buffer.asInt16List(
        data.offsetInBytes,
        data.lengthInBytes ~/ 2,
      );

      audioBuffer.addAll(int16Data);

      // BUFFER CUKUP
      if (audioBuffer.length >= expectedInputSize) {
        // AMBIL WINDOW TERAKHIR
        List<int> samples = audioBuffer.sublist(
          audioBuffer.length - expectedInputSize,
        );

        // BUFFER SHIFT
        audioBuffer = audioBuffer.sublist(
          audioBuffer.length - (expectedInputSize ~/ 2),
        );

        // DEBOUNCE
        debounceTimer?.cancel();

        debounceTimer = Timer(
          const Duration(milliseconds: 300),
          () {
            runInference(samples);
          },
        );
      }
    } catch (e) {
      print("PROCESS AUDIO ERROR: $e");
    }
  }

  // =========================================================
  // RUN INFERENCE
  // =========================================================

  Future<void> runInference(
    List<int> pcmData,
  ) async {
    if (_interpreter == null) return;

    if (_labels.isEmpty) return;

    if (isInferencing) return;

    try {
      isInferencing = true;

      // NORMALIZE AUDIO
      List<double> normalized = pcmData
          .map((e) => e / 32768.0)
          .toList();

      // INPUT SHAPE
      var input = [normalized];

      // OUTPUT
      var output = List.generate(
        1,
        (_) => List.filled(
          _labels.length,
          0.0,
        ),
      );

      // RUN MODEL
      _interpreter!.run(
        input,
        output,
      );

      List<double> probabilities =
          List<double>.from(output[0]);

      // CARI MAX
      double maxProb = 0.0;

      int maxIndex = 0;

      for (int i = 0;
          i < probabilities.length;
          i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];

          maxIndex = i;
        }
      }

      // THRESHOLD
      if (maxProb > 0.5) {
        predictedLabel.value =
            _labels[maxIndex];

        confidence.value = maxProb;
      } else {
        predictedLabel.value =
            "Tidak dikenali";

        confidence.value = maxProb;
      }

      print(
        "Prediction: ${predictedLabel.value}",
      );

      print(
        "Confidence: ${confidence.value}",
      );
    } catch (e) {
      print("INFERENCE ERROR: $e");
    } finally {
      isInferencing = false;
    }
  }
}