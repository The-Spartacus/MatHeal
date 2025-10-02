import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // <-- ADD THIS IMPORT

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

class FetalSizeWidget extends StatelessWidget {
  final int week;

  const FetalSizeWidget({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    // --- FIX: Correctly formatted data retrieval ---
    final closestWeek = _fetalSizeDataMap.keys.where((key) => key <= week).lastOrNull;
    final data = _fetalSizeDataMap[closestWeek ?? _fetalSizeDataMap.keys.first];
    
    if (data == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Theme.of(context).primaryColor.withOpacity(0.8),
        Theme.of(context).primaryColor.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- FIX: Replaced DecorationImage with SvgPicture.asset to correctly display SVG ---
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(0.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(1.0),
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SvgPicture.asset(
                'assets/images/Maternal.svg',
                colorFilter: const ColorFilter.mode(Color.fromARGB(255, 255, 118, 248), BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16.0),

            // --- UI IMPROVEMENT: Re-structured text for better readability ---
            Padding(
              padding: const EdgeInsets.all(0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $week Update',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2.0),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade300),
                          children: [
                            const TextSpan(text: 'Your baby is the size of a \n'),
                            TextSpan(
                              text: data.fruit,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1,color: Colors.white30),
                      _buildStatRow(context, icon: Icons.straighten, label: 'Length: ${data.length}'),
                      const SizedBox(height: 4),
                      _buildStatRow(context, icon: Icons.monitor_weight_outlined, label: 'Weight: ${data.weight}'),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }
  
  // Helper for displaying stats with icons
  Widget _buildStatRow(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}