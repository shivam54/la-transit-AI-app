import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/route_model.dart';
import '../providers/route_provider.dart';
import 'map_screen.dart';
import 'route_details_screen.dart';

/// DrivingRoutesScreen
///
/// Shows a list of driving route options and lets the user tap
/// into details or view the route on the map.
class DrivingRoutesScreen extends StatelessWidget {
  final List<RouteModel> routes;

  const DrivingRoutesScreen({
    super.key,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = routes.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasMultiple ? 'Driving Routes' : 'Best Driving Route'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          final isFirst = index == 0;
          return _DrivingRouteCard(
            route: route,
            highlighted: isFirst,
            onTap: () {
              final routeProvider = context.read<RouteProvider>();
              routeProvider.setRoute(route);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailsScreen(route: route),
                ),
              );
            },
            onViewMap: () {
              final routeProvider = context.read<RouteProvider>();
              routeProvider.setRoute(route);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MapScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DrivingRouteCard extends StatelessWidget {
  final RouteModel route;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onViewMap;

  const _DrivingRouteCard({
    required this.route,
    required this.highlighted,
    required this.onTap,
    required this.onViewMap,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1609.34).toStringAsFixed(1)} mi';
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours h $mins min' : '$hours h';
  }

  @override
  Widget build(BuildContext context) {
    final distance = _formatDistance(route.totalDistance);
    final duration = _formatDuration(route.totalDuration);
    final summary = route.summary ?? 'Via ${route.steps.isNotEmpty ? route.steps.first.instructions.replaceAll(RegExp(r'<[^>]*>'), '').split(' ').take(3).join(' ') : 'route'}';

    return Card(
      elevation: highlighted ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      highlighted ? 'BEST' : 'OPTION ${route.summary?.substring(0, 1) ?? ''}',
                      style: TextStyle(
                        color: highlighted ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.directions_car,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('View Directions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View Map'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

