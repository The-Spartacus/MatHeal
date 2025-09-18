import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/theme.dart';

class DietSuggestionsScreen extends StatefulWidget {
  const DietSuggestionsScreen({super.key});

  @override
  State<DietSuggestionsScreen> createState() => _DietSuggestionsScreenState();
}

class _DietSuggestionsScreenState extends State<DietSuggestionsScreen> {
  String? _suggestions;
  bool _isLoading = false;
  String? _error;

  Future<void> _generateSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final profile = userProvider.profile;
      final chatService = context.read<ChatService>();

      if (profile == null) {
        throw Exception("Please complete your profile to get personalized suggestions.");
      }

      // Construct a detailed prompt for the AI
      final prompt = """
        As a maternal health and nutrition expert, provide safe and conservative diet suggestions for a user with the following details:
        - Weeks Pregnant: ${profile.weeksPregnant ?? 'Not specified'}
        - Existing Health Conditions: ${profile.conditions.isNotEmpty ? profile.conditions.join(', ') : 'None specified'}

        Please structure your response into clear sections: 'Key Nutrients to Focus On', 'Foods to Eat', and 'Foods to Avoid'. 
        The advice must be general, easy to understand, and include a strong recommendation to consult a doctor before making any dietary changes.
        Do not diagnose or give medical advice for the specified conditions, only general dietary considerations.
      """;

      final response = await chatService.sendMessage(prompt);
      setState(() {
        _suggestions = response;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalized Diet Suggestions"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget(_error!)
                        : _suggestions != null
                            ? _buildSuggestionsCard(_suggestions!)
                            : _buildInitialState(),
              ),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.psychology_alt_outlined),
                  label: const Text('Generate My Suggestions'),
                  onPressed: _isLoading ? null : _generateSuggestions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.dining, size: 80, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Get AI-Powered Advice',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to generate diet tips based on your profile information.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuggestionsCard(String suggestions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          suggestions,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 60, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          'Could not generate suggestions',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
