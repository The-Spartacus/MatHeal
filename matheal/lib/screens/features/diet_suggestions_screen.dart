import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // ✅ Import the markdown package
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

      // ✅ --- PROMPT UPDATED TO REQUEST MARKDOWN TABLES ---
      final prompt = """
        As a maternal health and nutrition expert, create a one-day sample diet plan for a user with the following details:
        - Weeks Pregnant: ${profile.weeksPregnant ?? 'Not specified'}
        - Existing Health Conditions: ${profile.conditions.isNotEmpty ? profile.conditions.join(', ') : 'None specified'}

        Generate the response ONLY in Markdown format.

        First, create a table for 'Meal Suggestions' with the columns: 'Meal', 'Food Name', and 'Amount Of Food'. Include suggestions for Breakfast, Lunch, Dinner, and a Snack.

        Second, create another table for 'Foods to Generally Avoid' with the columns: 'Food/Drink' and 'Reason'.

        Finally, add a brief, one-sentence disclaimer at the end recommending the user to consult their doctor before making dietary changes. Do not provide any other text or introductions.
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
          'Tap the button below to generate diet tips in a table format.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ --- THIS WIDGET IS UPDATED TO RENDER MARKDOWN ---
  Widget _buildSuggestionsCard(String suggestions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // Use the MarkdownBody widget to display the table
        child: MarkdownBody(
          data: suggestions,
          styleSheet: MarkdownStyleSheet(
            tableBorder: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            tableHead: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            p: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    // ... (This widget remains the same)
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