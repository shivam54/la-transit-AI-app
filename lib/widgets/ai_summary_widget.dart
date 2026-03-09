import 'package:flutter/material.dart';
import '../services/ai_summary_service.dart';
import '../models/location_model.dart';

/// AI Summary Widget - Displays Gemini AI summaries for destinations
class AISummaryWidget extends StatefulWidget {
  final LocationModel destination;
  final String? placeId;

  const AISummaryWidget({
    super.key,
    required this.destination,
    this.placeId,
  });

  @override
  State<AISummaryWidget> createState() => _AISummaryWidgetState();
}

class _AISummaryWidgetState extends State<AISummaryWidget> {
  final AISummaryService _aiService = AISummaryService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (widget.placeId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final summary = await _aiService.getDestinationSummary(
        placeId: widget.placeId!,
        location: widget.destination,
        originalDestination: widget.destination.name,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading AI summary';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Loading AI insights...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _summary == null) {
      return const SizedBox.shrink(); // Hide if no summary available
    }

    // Extract summary text - handle both Map and nested structures
    String description = '';
    if (_summary is String) {
      description = _summary as String;
    } else if (_summary is Map) {
      final summaryMap = _summary as Map<String, dynamic>;
      // Handle nested content structure: {content: {text: "..."}}
      if (summaryMap['content'] is Map) {
        final content = summaryMap['content'] as Map<String, dynamic>;
        description = content['text']?.toString() ?? '';
      } else {
        // Fallback to direct fields
        description = summaryMap['description']?.toString() ?? 
                     summaryMap['overview']?.toString() ?? 
                     summaryMap['text']?.toString() ?? 
                     '';
      }
    }

    // As a final safeguard, always try to clean up any serialized-map style
    // strings so only the human-readable text is shown.
    description = _extractTextFromRawSummary(description);
    
    List<dynamic>? popularPlaces;
    if (_summary is Map) {
      final summaryMap = _summary as Map<String, dynamic>;
      // Check for referencedPlaces in the summary structure
      final places = summaryMap['referencedPlaces'] ?? summaryMap['popularPlaces'];
      if (places is List) {
        popularPlaces = places;
      }
    }

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero, // Remove margin since parent has padding
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary text
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),

            // Popular places
            if (popularPlaces != null && popularPlaces.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white54, height: 1),
              const SizedBox(height: 8),
              const Text(
                'Popular places nearby:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...popularPlaces.take(5).map((place) {
                final placeName = place is String ? place : place['name'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Expanded(
                        child: Text(
                          placeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Gemini label
            const SizedBox(height: 12),
            const Text(
              'Summarized with Gemini',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Some responses arrive as a Dart `Map.toString()` style string, e.g.:
  /// {content: {text: "...", languageCode: en-US, referencedPlaces: [...]}, ...}
  /// This helper tries to extract just the `text` field for display.
  String _extractTextFromRawSummary(String raw) {
    final trimmed = raw.trim();
    // If it doesn't look like a map, return as-is.
    if (!trimmed.startsWith('{') || !trimmed.contains('text:')) {
      return trimmed;
    }

    // Try to capture everything between "text:" and ", languageCode"
    final regex = RegExp(r'text:\s*(.*?),\s*languageCode', dotAll: true);
    final match = regex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final text = match.group(1)?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return trimmed;
  }
}

