import 'package:flutter/material.dart';
import '../../services/prediction_service.dart'; // Make sure this path is correct

class HealthRiskPredictor extends StatefulWidget {
  const HealthRiskPredictor({super.key});

  @override
  State<HealthRiskPredictor> createState() => _HealthRiskPredictorState();
}

class _HealthRiskPredictorState extends State<HealthRiskPredictor> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _systolicBpController = TextEditingController();
  final _diastolicBpController = TextEditingController();
  final _bsController = TextEditingController();
  final _bodyTempController = TextEditingController();
  final _heartRateController = TextEditingController();

  final PredictionService _predictionService = PredictionService();
  String _predictionResult = '';
  bool _isLoading = false;
  bool _isServiceReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize the service and enable the button when the model is loaded
    _predictionService.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isServiceReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _bsController.dispose();
    _bodyTempController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  void _predictRisk() {
    // Check if the form is valid before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = 'Analyzing...';
    });

    try {
      final result = _predictionService.predict(
        age: int.parse(_ageController.text),
        systolicBP: int.parse(_systolicBpController.text),
        diastolicBP: int.parse(_diastolicBpController.text),
        bs: double.parse(_bsController.text),
        bodyTemp: double.parse(_bodyTempController.text),
        heartRate: int.parse(_heartRateController.text),
      );

      setState(() {
        _predictionResult = 'Predicted Risk: $result';
      });

    } catch (e) {
      setState(() {
        _predictionResult = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maternal Health Risk')),
      body: !_isServiceReady
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing prediction model...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextFormField(_ageController, 'Age'),
                    _buildTextFormField(_systolicBpController, 'Systolic Blood Pressure (e.g., 120)'),
                    _buildTextFormField(_diastolicBpController, 'Diastolic Blood Pressure (e.g., 80)'),
                    _buildTextFormField(_bsController, 'Blood Sugar (BS)', isDouble: true),
                    _buildTextFormField(_bodyTempController, 'Body Temperature (°F)', isDouble: true),
                    _buildTextFormField(_heartRateController, 'Heart Rate (BPM)'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading || !_isServiceReady ? null : _predictRisk,
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) 
                          : const Text('Predict Risk'),
                    ),
                    const SizedBox(height: 20),
                    if (_predictionResult.isNotEmpty)
                      Text(
                        _predictionResult,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isDouble = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isDouble 
            ? const TextInputType.numberWithOptions(decimal: true) 
            : TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (isDouble) {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
          } else {
            if (int.tryParse(value) == null) {
              return 'Please enter a valid whole number';
            }
          }
          return null; // Return null if the input is valid
        },
      ),
    );
  }
}