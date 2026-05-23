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
  final predictedLabel = "Select WAV File".obs;
  final confidence = 0.0.obs;
  final isLoading = false.obs;

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
      predictedLabel.value = "Loading model...";

      final labelData = await rootBundle.loadString(
        'assets/ml/labels.txt',
      );

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

      _interpreter = await Interpreter.fromAsset(
        'assets/ml/soundclassifier_with_metadata.tflite',
      );

      predictedLabel.value = "Model Ready";
    } catch (e) {
      predictedLabel.value = "Failed load model";

      print("LOAD MODEL ERROR: $e");
    }
  }

  Future<void> pickAndClassifyFile() async {
    try {
      isLoading.value = true;

      FilePickerResult? result =
          await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav'],
      );

      if (result == null ||
          result.files.isEmpty) {
        isLoading.value = false;
        return;
      }

      final file = result.files.first;

      if (file.path == null) {
        predictedLabel.value = "Invalid file";

        isLoading.value = false;
        return;
      }

      selectedFileName.value = file.name;
      predictedLabel.value = "Processing...";
      confidence.value = 0.0;

      final wavFile = File(file.path!);

      Uint8List bytes =
          await wavFile.readAsBytes();

      if (bytes.length < 44) {
        predictedLabel.value =
            "Invalid WAV file";

        isLoading.value = false;
        return;
      }

      // Skip WAV Header
      Uint8List pcmBytes =
          bytes.sublist(44);

      Int16List pcmData =
          pcmBytes.buffer.asInt16List(
        pcmBytes.offsetInBytes,
        pcmBytes.lengthInBytes ~/ 2,
      );

      List<double> input =
          _prepareInput(pcmData);

      _runInference(input);

      isLoading.value = false;
    } catch (e) {
      predictedLabel.value =
          "Error processing file";

      isLoading.value = false;

      print("UPLOAD ERROR: $e");
    }
  }

  List<double> _prepareInput(
      Int16List pcmData) {
    List<double> normalized =
        pcmData
            .map(
              (e) => e / 32768.0,
            )
            .toList();

    // trim
    if (normalized.length >
        _expectedInputSize) {
      normalized = normalized.sublist(
        0,
        _expectedInputSize,
      );
    }

    // padding
    while (normalized.length <
        _expectedInputSize) {
      normalized.add(0.0);
    }

    return normalized;
  }

  void _runInference(
      List<double> inputData) {
    try {
      if (_interpreter == null) {
        predictedLabel.value =
            "Interpreter null";
        return;
      }

      if (_labels.isEmpty) {
        predictedLabel.value =
            "Labels empty";
        return;
      }

      var input = [inputData];

      var output = List.generate(
        1,
        (_) => List.filled(
          _labels.length,
          0.0,
        ),
      );

      _interpreter!.run(
        input,
        output,
      );

      List<double> probabilities =
          List<double>.from(output[0]);

      double maxProb = 0.0;
      int maxIndex = 0;

      for (int i = 0;
          i < probabilities.length;
          i++) {
        if (probabilities[i] >
            maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      predictedLabel.value =
          _labels[maxIndex];

      confidence.value = maxProb;

      print(
        "Prediction: ${_labels[maxIndex]}",
      );

      print(
        "Confidence: $maxProb",
      );
    } catch (e) {
      predictedLabel.value =
          "Inference Error";

      print(
        "INFERENCE ERROR: $e",
      );
    }
  }
}