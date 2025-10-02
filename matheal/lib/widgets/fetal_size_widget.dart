import 'package:flutter/material.dart';

// The data model and data map remain the same
class FetalSizeData {
  final String fruit;
  final String imageUrl;
  final String length;
  final String weight;

  FetalSizeData({
    required this.fruit,
    required this.imageUrl,
    required this.length,
    required this.weight,
  });
}

final Map<int, FetalSizeData> _fetalSizeDataMap = {
  4: FetalSizeData(fruit: 'Poppy Seed', imageUrl: 'https://i.imgur.com/2X20h6B.png', length: '0.1 cm', weight: '<1 g'),
  8: FetalSizeData(fruit: 'Raspberry', imageUrl: 'https://i.imgur.com/pDF2wGz.png', length: '1.6 cm', weight: '1 g'),
  12: FetalSizeData(fruit: 'Lime', imageUrl: 'https://i.imgur.com/g055zP3.png', length: '5.4 cm', weight: '14 g'),
  16: FetalSizeData(fruit: 'Avocado', imageUrl: 'https://i.imgur.com/aN329gR.png', length: '11.6 cm', weight: '100 g'),
  20: FetalSizeData(fruit: 'Banana', imageUrl: 'https://i.imgur.com/Uf7b7t8.png', length: '25.6 cm', weight: '300 g'),
  24: FetalSizeData(fruit: 'Cantaloupe', imageUrl: 'https://i.imgur.com/z6b3cfc.png', length: '30 cm', weight: '600 g'),
  28: FetalSizeData(fruit: 'Eggplant', imageUrl: 'https://i.imgur.com/7ZQbB8p.png', length: '37.6 cm', weight: '1 kg'),
  32: FetalSizeData(fruit: 'Jicama', imageUrl: 'https://i.imgur.com/iI3gN6c.png', length: '42.4 cm', weight: '1.7 kg'),
  36: FetalSizeData(fruit: 'Honeydew Melon', imageUrl: 'https://i.imgur.com/G5g22mF.png', length: '47.4 cm', weight: '2.6 kg'),
  40: FetalSizeData(fruit: 'Watermelon', imageUrl: 'https://i.imgur.com/kSj2pEM.png', length: '51.2 cm', weight: '3.4 kg'),
};

class FetalSizeWelcomeCard extends StatelessWidget {
  final int week;

  const FetalSizeWelcomeCard({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final data = _fetalSizeDataMap[week] ?? _fetalSizeDataMap[4];
    if (data == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          print('Fetal size card tapped!');
        },
        child: Container(
          decoration: BoxDecoration(
            // --- vvvv CHANGES ARE HERE vvvv ---
            
            // Replace the 'gradient' with an 'image' decoration
            image: DecorationImage(
              image: const AssetImage('assets/images/card_background.png'),
              fit: BoxFit.cover,
              // Optional: This adds a dark overlay to make white text more readable
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
            
            // --- ^^^^ CHANGES ARE HERE ^^^^
            
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image.network(
                      data.imageUrl,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week $week Update",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                          children: [
                            const TextSpan(
                              text: 'Your baby is the size of a ',
                            ),
                            TextSpan(
                              text: data.fruit,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}