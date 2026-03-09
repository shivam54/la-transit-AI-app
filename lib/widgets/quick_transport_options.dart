import 'package:flutter/material.dart';

/// Quick Transport Options Widget - mirrors the web app's “Quick Transport Options” card.
class QuickTransportOptions extends StatelessWidget {
  final String transportMode; // 'public_transit', 'drive', 'walk', 'bike'
  final String? origin;
  final String? destination;

  const QuickTransportOptions({
    super.key,
    required this.transportMode,
    this.origin,
    this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = _getRecommendations(transportMode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('🚀', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'Quick Transport Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recommended route card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendations['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bullet points
                  ...(recommendations['points'] as List<dynamic>).map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point['icon'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point['text'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Alternative hint
                  if (recommendations['alternative'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔀', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendations['alternative'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getRecommendations(String mode) {
    switch (mode) {
      case 'public_transit':
        // Transit is primary, driving / ride-share is just an alternative.
        return {
          'title': 'Metro Only (Avoid Traffic)',
          'points': [
            {'icon': '🔴', 'text': 'Heavy traffic conditions'},
            {'icon': '🎉', 'text': 'Special events causing crowds'},
            {'icon': '⏰', 'text': 'Rush hour – Metro is faster'},
          ],
          'alternative':
              'Looking for other options? Try Drive for turn‑by‑turn navigation or Ride Share for door‑to‑door service.',
        };
      case 'drive':
        return {
          'title': 'Driving (Leave a Little Early)',
          'points': [
            {'icon': '🔴', 'text': 'Normal traffic conditions'},
            {'icon': '🎉', 'text': 'Special events causing crowds'},
            {
              'icon': '🚗',
              'text':
                  'Looking for other options? Try Ride Share (Uber/Lyft) for pickup at your location.'
            },
          ],
        };
      case 'walk':
        return {
          'title': 'Walking (Best for Short Distances)',
          'points': [
            {'icon': '🚶', 'text': 'Healthy and eco‑friendly'},
            {'icon': '💰', 'text': 'No cost'},
            {'icon': '⏰', 'text': 'Best for distances under 1 mile'},
          ],
        };
      case 'bike':
        return {
          'title': 'Biking (Fast & Healthy)',
          'points': [
            {'icon': '🚴', 'text': 'Avoid traffic'},
            {'icon': '💪', 'text': 'Get exercise'},
            {'icon': '🌱', 'text': 'Eco‑friendly'},
          ],
        };
      default:
        return {
          'title': 'Recommended Route',
          'points': [
            {'icon': '📍', 'text': 'Best option for your trip'},
          ],
        };
    }
  }
}


