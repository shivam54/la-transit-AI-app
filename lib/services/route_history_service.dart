import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// RouteHistoryService
///
/// Handles logging of planned routes to Supabase (`route_searches` table)
/// and fetching the most frequently used routes for a given user.
class RouteHistoryService {
  RouteHistoryService._internal();
  static final RouteHistoryService _instance = RouteHistoryService._internal();
  static RouteHistoryService get instance => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Log a planned route for the given user.
  ///
  /// `originDisplay` and `destinationDisplay` should be human‑readable
  /// addresses/names (not raw coordinates).
  Future<void> logRoute({
    required String userId,
    required String originDisplay,
    required String destinationDisplay,
  }) async {
    try {
      await _client.from('route_searches').insert(<String, dynamic>{
        'user_id': userId,
        'origin': originDisplay,
        'destination': destinationDisplay,
        'search_timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // For now, just log to console; we don't want to block the UI.
      // ignore: avoid_print
      print('⚠️ Failed to log route_search: $e');
    }
  }
}

/// Lightweight model for a suggested frequent route.
class SuggestedRoute {
  final String origin;
  final String destination;
  final int usageCount;

  SuggestedRoute({
    required this.origin,
    required this.destination,
    required this.usageCount,
  });
}

extension RouteHistoryQueries on RouteHistoryService {
  /// Fetch top 2 most‑used routes for the given user.
  ///
  /// We pull recent history and aggregate in Dart to keep the query simple.
  Future<List<SuggestedRoute>> getTopRoutesForUser(
    String userId, {
    int limit = 2,
  }) async {
    try {
      final response = await _client
          .from('route_searches')
          .select('origin, destination, search_timestamp')
          .eq('user_id', userId)
          .order('search_timestamp', ascending: false)
          .limit(100);

      if (response is! List) return [];

      final Map<String, _RouteUsage> usageMap = {};

      for (final row in response) {
        final origin = (row['origin'] ?? '').toString().trim();
        final destination = (row['destination'] ?? '').toString().trim();
        if (origin.isEmpty || destination.isEmpty) continue;

        final key = '$origin|$destination';
        final tsString = row['search_timestamp']?.toString();
        DateTime ts;
        try {
          ts = tsString != null ? DateTime.parse(tsString) : DateTime.now();
        } catch (_) {
          ts = DateTime.now();
        }

        final existing = usageMap[key];
        if (existing == null) {
          usageMap[key] = _RouteUsage(
            origin: origin,
            destination: destination,
            count: 1,
            lastUsed: ts,
          );
        } else {
          existing.count += 1;
          if (ts.isAfter(existing.lastUsed)) {
            existing.lastUsed = ts;
          }
        }
      }

      final usages = usageMap.values.toList()
        ..sort((a, b) {
          final c = b.count.compareTo(a.count);
          if (c != 0) return c;
          return b.lastUsed.compareTo(a.lastUsed);
        });

      return usages
          .take(limit)
          .map((u) => SuggestedRoute(
                origin: u.origin,
                destination: u.destination,
                usageCount: u.count,
              ))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Failed to load suggested routes: $e');
      return [];
    }
  }
}

class _RouteUsage {
  final String origin;
  final String destination;
  int count;
  DateTime lastUsed;

  _RouteUsage({
    required this.origin,
    required this.destination,
    required this.count,
    required this.lastUsed,
  });
}


