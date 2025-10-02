import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionService {
  Interpreter? _interpreter;
  final _riskLabels = ['high risk', 'low risk', 'mid risk'];

  PredictionService();

  /// Loads the TFLite model from assets. Call this when the app or screen starts.
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      debugPrint('✅ Prediction model loaded successfully.');
    } catch (e) {
      debugPrint('❌ Error loading prediction model: $e');
    }
  }

  /// Takes user input and returns a predicted risk level.
  String predict({
    required int age,
    required int systolicBP,
    required int diastolicBP,
    required double bs,
    required double bodyTemp,
    required int heartRate,
  }) {
    if (_interpreter == null) {
      throw Exception("Interpreter not initialized. Call initialize() first.");
    }

    // This scaling should match the scaling used during model training in Python.
    var input = [
      [
        (age - 29) / 13.0,
        (systolicBP - 113) / 13.0,
        (diastolicBP - 78) / 10.0,
        (bs - 8.7) / 3.2,
        (bodyTemp - 98.6) / 1.4,
        (heartRate - 74) / 6.0
      ]
    ];

    // Prepare the output buffer
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // Run the prediction
    _interpreter!.run(input, output);

    // Find the index with the highest probability
    double highestProb = 0;
    int bestIndex = 0;
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];
        bestIndex = i;
      }
    }

    return _riskLabels[bestIndex];
  }
}   