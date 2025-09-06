import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        // You can add actions like a share button here
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Handle share action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image
            Image.asset(
              'assets/images/article_image.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
            ),
            
            // Article Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Title
                  const Text(
                    'The Importance of Prenatal Care',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Article Metadata (Author, Date)
                  const Text(
                    'By MatHeal Health | September 5, 2024',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Article Body
                  const Text(
                    'Prenatal care is a crucial aspect of a healthy pregnancy, ensuring both the mother and baby are safe and well. Regular check-ups allow healthcare providers to monitor the mother’s health and the baby’s development, detect potential complications early, and provide guidance on diet, exercise, and lifestyle changes.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'During these visits, doctors can perform various tests, such as blood pressure checks, urine tests, and ultrasounds. These tests help in identifying conditions like gestational diabetes or pre-eclampsia, which can be managed effectively with early intervention. Moreover, it is an opportunity for expectant mothers to ask questions and receive personalized advice.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'In addition to physical health, prenatal care also addresses mental and emotional well-being. Healthcare professionals can offer support and resources for managing stress, anxiety, or other mental health challenges that may arise during pregnancy. A supportive network and professional guidance can make a significant difference in a positive pregnancy experience.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}