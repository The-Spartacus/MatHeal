import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/diet_model.dart'; // Make sure models are imported
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart'; // Make sure service is imported
import '../../utils/theme.dart';

class DietSuggestionsScreen extends StatefulWidget {
  const DietSuggestionsScreen({super.key});

  @override
  State<DietSuggestionsScreen> createState() => _DietSuggestionsScreenState();
}

class _DietSuggestionsScreenState extends State<DietSuggestionsScreen> {
  //isLoading is for the button's state, the FutureBuilder handles the main UI loading
  bool _isLoading = false;
  late Future<DietChatEntry?> _suggestionFuture;

  @override
  void initState() {
    super.initState();
    // Load the most recent suggestion from Firestore when the screen loads
    _loadInitialSuggestion();
  }

  void _loadInitialSuggestion() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _suggestionFuture =
          context.read<FirestoreService>().getLatestDietSuggestion(user.uid);
    } else {
      // If no user is logged in, set the future to null
      _suggestionFuture = Future.value(null);
    }
  }

  Future<void> _generateSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final chatService = context.read<ChatService>();
      final firestoreService = context.read<FirestoreService>();
      final user = userProvider.user;
      final profile = userProvider.profile;

      if (profile == null || user == null) {
        throw Exception("User profile not found. Please complete your profile first.");
      }

      final prompt = """
        As a maternal health and nutrition expert, create a one-day sample diet plan for a user with the following details:
        - Weeks Pregnant: ${profile.currentWeeksPregnant ?? 'Not specified'}
        - Existing Health Conditions: ${profile.conditions.isNotEmpty ? profile.conditions.join(', ') : 'None specified'}

        Generate the response ONLY in Markdown format.

        First, create a table for 'Meal Suggestions' with the columns: 'Meal', 'Food Name', and 'Amount Of Food'. Include suggestions for Breakfast, Lunch, Dinner, and a Snack.

        Second, create another table for 'Foods to Generally Avoid' with the columns: 'Food/Drink' and 'Reason'.

        Finally, add a brief, one-sentence disclaimer at the end recommending the user to consult their doctor before making dietary changes. Do not provide any other text or introductions.
      """;

      final response = await chatService.sendMessage(prompt);

      final newSuggestion = DietChatEntry(
        userId: user.uid,
        prompt: "User requested a diet plan in table format.",
        response: response,
        timestamp: DateTime.now(),
      );

      await firestoreService.saveDietSuggestion(newSuggestion);
      print("✅ Table data saved to Firestore successfully!");

      // After saving, refresh the FutureBuilder to show the new data instantly
      setState(() {
        _suggestionFuture = Future.value(newSuggestion);
      });

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // THE DISPLAY AREA IS NOW MANAGED BY FutureBuilder
            Expanded(
              child: FutureBuilder<DietChatEntry?>(
                future: _suggestionFuture,
                builder: (context, snapshot) {
                  // 1. While loading data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // 2. If an error occurred
                  if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  }
                  // 3. If data is loaded, but it's empty (no previous suggestions)
                  if (!snapshot.hasData || snapshot.data == null) {
                    return _buildInitialState();
                  }
                  // 4. If we have data, display it
                  return _buildSuggestionsCard(snapshot.data!.response);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Generate New Suggestions'),
                onPressed: _isLoading ? null : _generateSuggestions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... All your other widgets (_buildInitialState, _buildSuggestionsCard, etc.) remain the same
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

  Widget _buildSuggestionsCard(String suggestions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
