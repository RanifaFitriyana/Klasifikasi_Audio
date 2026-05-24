import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class UploadAudioController extends GetxController {
  Interpreter? _interpreter;
  List<String> _labels = [];

  final selectedFileName = "No file selected".obs;
  final predictedLabel = "Select a WAV file".obs;
  final confidence = 0.0.obs;

  static const int _expectedInputSize = 15600;

  @override
  void onInit() {
    super.onInit();
    _loadModelAndLabels();
  }

  @override
  void onClose() {
    _interpreter?.close();
    super.onClose();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelData.split('\n').where((line) => line.isNotEmpty)
          .map((line) => line.split(' ').sublist(1).join(' ')).toList();

      _interpreter = await Interpreter.fromAsset('assets/ml/soundclassifier_with_metadata.tflite');
    } catch (e) {
      predictedLabel.value = "Failed to load model: $e";
    }
  }

  Future<void> pickAndClassifyFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

      if (result != null && result.files.isNotEmpty) {
        String? path = result.files.first.path;
        if (path != null) {
          selectedFileName.value = result.files.first.name;
          predictedLabel.value = "Processing...";
          confidence.value = 0.0;

          File file = File(path);
          Uint8List bytes = await file.readAsBytes();

          int headerSize = 44; // WAV header
          if (bytes.length <= headerSize) {
            predictedLabel.value = "Invalid audio file";
            return;
          }

          Uint8List audioData = bytes.sublist(headerSize);
          Int16List int16Data = audioData.buffer.asInt16List(audioData.offsetInBytes, audioData.lengthInBytes ~/ 2);

          List<int> samplesToProcess = [];
          if (int16Data.length >= _expectedInputSize) {
            samplesToProcess = int16Data.sublist(0, _expectedInputSize);
          } else {
            samplesToProcess = int16Data.toList();
            while (samplesToProcess.length < _expectedInputSize) {
              samplesToProcess.add(0);
            }
          }

          _runInference(samplesToProcess);
        }
      }
    } catch (e) {
      predictedLabel.value = "Error picking file: $e";
    }
  }

  void _runInference(List<int> pcmData) {
    if (_interpreter == null || _labels.isEmpty) return;

    List<double> inputData = pcmData.map((e) => e / 32768.0).toList();
    var input = [inputData];
    var output = List.filled(1, List.filled(_labels.length, 0.0));

    try {
      _interpreter!.run(input, output);
      List<double> probabilities = output[0];

      double maxProb = 0.0;
      int maxIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxIndex != -1) {
        predictedLabel.value = _labels[maxIndex];
        confidence.value = maxProb;
      }
    } catch (e) {
      predictedLabel.value = "Inference error";
    }
  }
}