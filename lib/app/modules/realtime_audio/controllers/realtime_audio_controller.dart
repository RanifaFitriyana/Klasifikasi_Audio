import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RealtimeAudioController extends GetxController {
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Interpreter? _interpreter;
  List<String> _labels = [];

  final isRecording = false.obs;
  final predictedLabel = "Loading...".obs;
  final confidence = 0.0.obs;
  final labelProbabilities = <String, double>{}.obs;

  static const int _sampleRate = 44100;
  static const int _expectedInputSize = 44032;
  
  List<int> _audioBuffer = [];

  @override
  void onInit() {
    super.onInit();
    _loadModelAndLabels();
  }

  @override
  void onClose() {
    _stopRecording();
    _audioRecorder.dispose();
    _interpreter?.close();
    super.onClose();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.split(' ').sublist(1).join(' '))
          .toList();

      _interpreter = await Interpreter.fromAsset('assets/ml/soundclassifier_with_metadata.tflite');
      predictedLabel.value = "Ready to record";
      for (var label in _labels) {
        labelProbabilities[label] = 0.0;
      }
    } catch (e) {
      predictedLabel.value = "Failed to load model: $e";
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        predictedLabel.value = "Microphone permission denied";
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        final stream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ));

        _audioBuffer.clear();
        isRecording.value = true;
        predictedLabel.value = "Listening...";

        _audioStreamSubscription = stream.listen((Uint8List data) {
          _processAudioData(data);
        });
      }
    } catch (e) {
      predictedLabel.value = "Error starting record: $e";
    }
  }

  Future<void> _stopRecording() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _audioRecorder.stop();
    isRecording.value = false;
    predictedLabel.value = "Ready to record";
    confidence.value = 0.0;
  }

  void _processAudioData(Uint8List data) {
    Int16List int16Data;
    if (data.offsetInBytes % 2 == 0) {
      int16Data = data.buffer.asInt16List(data.offsetInBytes, data.lengthInBytes ~/ 2);
    } else {
      final alignedData = Uint8List.fromList(data);
      int16Data = alignedData.buffer.asInt16List(0, alignedData.lengthInBytes ~/ 2);
    }
    _audioBuffer.addAll(int16Data);

    if (_audioBuffer.length >= _expectedInputSize) {
      List<int> samplesToProcess = _audioBuffer.sublist(_audioBuffer.length - _expectedInputSize);
      _audioBuffer = _audioBuffer.sublist(_audioBuffer.length - (_expectedInputSize ~/ 2));
      _runInference(samplesToProcess);
    }
  }

  void _runInference(List<int> pcmData) {
    if (_interpreter == null || _labels.isEmpty) return;

    // Input: Float32List to guarantee native 32-bit float layout alignment (avoids NaN).
    Float32List inputBuffer = Float32List(pcmData.length);
    for (int i = 0; i < pcmData.length; i++) {
      inputBuffer[i] = pcmData[i] / 32768.0;
    }

    try {
      // === DIRECT RAW BYTE ACCESS ===
      // Write input: copy Float32List bytes directly into the input tensor's raw Uint8List buffer.
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputBytes = inputBuffer.buffer.asUint8List(
        inputBuffer.offsetInBytes,
        inputBuffer.lengthInBytes,
      );
      inputTensor.data.setRange(0, inputBytes.length, inputBytes);

      // Invoke the interpreter.
      _interpreter!.invoke();

      // Read output: copy raw bytes from output tensor and reinterpret as Float32List.
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputBytes = Uint8List.fromList(outputTensor.data);
      final outputFloat32 = outputBytes.buffer.asFloat32List();
      List<double> probabilities = outputFloat32.map((e) => e.toDouble()).toList();

      double maxProb = double.negativeInfinity;
      int maxIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxIndex != -1 && maxIndex < _labels.length) {
        predictedLabel.value = _labels[maxIndex];
        confidence.value = maxProb;
      }
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        labelProbabilities[_labels[i]] = probabilities[i];
      }
      labelProbabilities.refresh();
    } catch (e) {
      predictedLabel.value = "Inference error: $e";
    }
  }
}