import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../screens/route_details_screen.dart';
import 'transit_route_segments.dart';

/// Best Route Card - Shows recommended route with click to view
class BestRouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback? onTap;

  const BestRouteCard({
    super.key,
    required this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final durationMinutes = (route.totalDuration / 60).round();
    final distanceMiles = (route.totalDistance / 1609.34).toStringAsFixed(1);
    
    // Calculate arrival time
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(seconds: route.totalDuration));
    final arrivalTimeStr = '${arrivalTime.hour % 12 == 0 ? 12 : arrivalTime.hour % 12}:${arrivalTime.minute.toString().padLeft(2, '0')}${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailsScreen(route: route),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - "Best Transit Route"
              const Text(
                'Best Transit Route',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Route summary with arrival time
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${route.origin.name ?? route.origin.address ?? 'Origin'} -- ${route.destination.name ?? route.destination.address ?? 'Destination'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'arrives $arrivalTimeStr',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Route segments using TransitRouteSegments widget
              TransitRouteSegments(
                transitDetails: route.transitDetails,
                steps: route.steps,
              ),

              const SizedBox(height: 12),

              // Duration (shown on the right)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$durationMinutes min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              
              // View This Route button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View This Route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


