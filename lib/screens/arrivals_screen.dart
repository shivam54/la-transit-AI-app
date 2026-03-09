import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../services/transit_service.dart';
import '../utils/route_display.dart';
import 'realtime_map_screen.dart';

/// ArrivalsScreen
///
/// Shows real-time transit arrivals for a route.
/// Allows users to check arrivals for stops in the route or open Metro.net arrivals page.
class ArrivalsScreen extends StatefulWidget {
  final RouteModel route;

  const ArrivalsScreen({
    super.key,
    required this.route,
  });

  @override
  State<ArrivalsScreen> createState() => _ArrivalsScreenState();
}

class _ArrivalsScreenState extends State<ArrivalsScreen> {
  final TransitService _transitService = TransitService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _arrivals = [];
  String? _error;
  String? _selectedRouteId;
  String? _selectedStopName;

  @override
  void initState() {
    super.initState();
    _loadArrivals();
  }

  Future<void> _loadArrivals() async {
    final transitDetails = widget.route.transitDetails ?? [];
    if (transitDetails.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the first transit detail to extract route info
      final firstTransit = transitDetails.first;
      final line = firstTransit['line'] ?? {};
      final routeNumber = (line['short_name'] ?? line['shortName'] ?? '').toString();
      final routeName = (line['name'] ?? line['long_name'] ?? '').toString();
      // For Metro rail only (e.g. "Metro D Line", "Metro B Line"), use full name; for buses use short_name
      final isLikelyRail = RegExp(r'Metro\s+[A-Z]\s+Line', caseSensitive: false).hasMatch(routeName);
      final routeIdForApi = isLikelyRail ? routeName : routeNumber;
      final departureStop = firstTransit['departure_stop'] ?? {};
      final stopLocation = departureStop['location'] ?? {};
      final lat = stopLocation['lat'] ?? stopLocation['latitude'];
      final lng = stopLocation['lng'] ?? stopLocation['longitude'];
      
      // Try to get stop ID from Google, or resolve from departure stop name/location so we show arrivals at YOUR stop only
      String? stopId = departureStop['stop_id']?.toString();
      final stopName = departureStop['name']?.toString() ?? 'Stop';
      _selectedRouteId = routeNumber.isNotEmpty ? routeNumber : routeIdForApi;
      _selectedStopName = stopName;

      if ((stopId == null || stopId.isEmpty) && stopName.isNotEmpty) {
        stopId = await _transitService.resolveStopId(
          stopName: stopName,
          latitude: lat != null ? (lat as num).toDouble() : null,
          longitude: lng != null ? (lng as num).toDouble() : null,
        );
      }

      // Get arrivals filtered by departure stop when we have stop_id. For DASH, also send stop name so backend can resolve LADOT stop.
      List<Map<String, dynamic>> arrivals = [];
      if (routeIdForApi.isNotEmpty) {
        arrivals = await _transitService.getArrivalsFromTripUpdates(
          routeId: routeIdForApi,
          latitude: lat != null ? (lat as num).toDouble() : null,
          longitude: lng != null ? (lng as num).toDouble() : null,
          stopId: stopId,
          stopName: stopName.isNotEmpty ? stopName : null,
        );
      }

      if (mounted) {
        final routeFoundInCache = _transitService.lastRouteFoundInCache;
        final routeLabel = displayRouteLabel(_selectedRouteId);
        setState(() {
          _arrivals = arrivals;
          _isLoading = false;
          if (arrivals.isEmpty) {
            // 4X is Torrance Transit — real-time not in Metro/Swiftly feed
            if (_selectedRouteId?.toUpperCase() == '4X') {
              _error = '4X is a Torrance Transit route. Real-time arrivals aren\'t available here. Check Metro.net or Torrance Transit for schedules.';
            } else if (routeFoundInCache == false) {
              _error = 'Route $routeLabel has no real-time data in the feed right now. Try again in a few minutes or check Metro.net.';
            } else {
              _error = 'No arrivals in the next few minutes at $_selectedStopName. Try again shortly or check Metro.net.';
            }
          } else {
            _error = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading arrivals: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transitDetails = widget.route.transitDetails ?? [];
    
    if (transitDetails.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Check Arrivals'),
        ),
        body: const Center(
          child: Text('No transit information available for this route.'),
        ),
      );
    }

    // Get the first transit detail to extract route info
    final firstTransit = transitDetails.first;
    final line = firstTransit['line'] ?? {};
    final routeNumber = (line['short_name'] ?? line['shortName'] ?? '').toString();
    final routeName = (line['name'] ?? line['long_name'] ?? '').toString();
    final departureStop = firstTransit['departure_stop'] ?? {};
    final stopName = departureStop['name']?.toString() ?? 'Stop';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Arrivals'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routeNumber.isNotEmpty ? 'Route ${displayRouteLabel(routeNumber)}' : 'Transit Route',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (routeName.isNotEmpty)
                                Text(
                                  routeName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Departure Stop: $stopName',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // View Live Map Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RealtimeMapScreen(route: widget.route),
                    ),
                  );
                },
                icon: const Icon(Icons.map, size: 20),
                label: const Text('View Live Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Real-time Arrivals Section
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadArrivals,
                      tooltip: 'Retry',
                    ),
                  ],
                ),
              )
            else if (_arrivals.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No real-time arrivals found. You can check Metro.net for schedule information.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMetroArrivals,
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text('Open Metro.net Arrivals'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Arrivals List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Real-Time Arrivals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadArrivals,
                    tooltip: 'Refresh arrivals',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._arrivals.map((arrival) => _buildArrivalCard(arrival)),
            ],
            const SizedBox(height: 24),

            // All Transit Stops in Route
            if (transitDetails.length > 1) ...[
              const Text(
                'Transit Stops in This Route:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...transitDetails.asMap().entries.map((entry) {
                final index = entry.key;
                final detail = entry.value;
                final depStop = detail['departure_stop'] ?? {};
                final arrStop = detail['arrival_stop'] ?? {};
                final lineInfo = detail['line'] ?? {};
                final lineNum = (lineInfo['short_name'] ?? lineInfo['shortName'] ?? '').toString();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        lineNum.isNotEmpty ? displayRouteLabel(lineNum) : '${index + 1}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      depStop['name']?.toString() ?? 'Stop ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'To: ${arrStop['name']?.toString() ?? 'Next stop'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openMetroArrivals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Open Metro.net arrivals page
      final metroUrl = Uri.parse('https://metro.net/riding/nextrip/');
      
      if (await canLaunchUrl(metroUrl)) {
        await launchUrl(
          metroUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Metro.net arrivals page.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening arrivals page: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildArrivalCard(Map<String, dynamic> arrival) {
    // Ensure we use local time for display (backend may send UTC)
    final arrivalTime = (arrival['arrival_time'] as DateTime).toLocal();
    // Recompute from actual arrival time so "now" is the user's current time, not server cache time
    final now = DateTime.now();
    final minutesUntil = arrivalTime.isBefore(now)
        ? 0
        : arrivalTime.difference(now).inMinutes;
    final secondsUntil = arrivalTime.isBefore(now)
        ? 0
        : arrivalTime.difference(now).inSeconds;

    final routeId = arrival['route_id']?.toString().trim() ?? _selectedRouteId ?? '';
    final vehicleId = arrival['vehicle_id']?.toString().trim() ?? '';
    final headsign = arrival['headsign']?.toString().trim() ?? '';
    final stopName = arrival['stop_name']?.toString().trim() ?? '';
    final delay = arrival['delay'] as int? ?? 0;
    final isDelayed = delay > 0;
    final isOnTime = delay == 0;
    final isEarly = delay < 0;

    final timeFormat = DateFormat('h:mm a');
    final arrivalTimeStr = timeFormat.format(arrivalTime);

    // Show combined label (e.g. "14/37") so header and cards match and user isn't confused
    final routeNum = displayRouteLabel(_selectedRouteId ?? routeId);
    // For rail, Swiftly often returns multiple car numbers like "1100-1107-1117".
    // Show only the first identifier to keep the pill compact.
    String primaryVehicle = '';
    if (vehicleId.isNotEmpty) {
      primaryVehicle = vehicleId.split(RegExp(r'[\\s,-]+')).firstWhere(
            (p) => p.isNotEmpty,
            orElse: () => vehicleId,
          );
    }
    final busLabel = primaryVehicle.isNotEmpty ? 'Bus #$primaryVehicle' : '';

    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (isEarly) {
      statusColor = Colors.blue;
      statusText = '${delay.abs()} min early';
      statusIcon = Icons.trending_down;
    } else if (isDelayed) {
      statusColor = Colors.orange;
      statusText = delay >= 60 ? '${(delay / 60).round()} min delay' : '$delay sec delay';
      statusIcon = Icons.trending_up;
    } else {
      statusColor = Colors.green;
      statusText = 'On time';
      statusIcon = Icons.check_circle;
    }

    // "Arriving now" only when really due in the next 60 seconds; otherwise show minutes or time
    String whenText;
    if (secondsUntil <= 60 && !arrivalTime.isBefore(now)) {
      whenText = secondsUntil <= 0 ? 'Arriving now' : 'In ${secondsUntil}s';
    } else if (minutesUntil == 0) {
      whenText = 'Due $arrivalTimeStr';
    } else if (minutesUntil == 1) {
      whenText = 'In 1 min';
    } else {
      whenText = 'In $minutesUntil min';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Compact route pill on the left (bus + rail look the same)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routeNum.isNotEmpty ? routeNum : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (busLabel.isNotEmpty)
                    Text(
                      busLabel.replaceFirst('Bus #', ''),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right: times + stop + status, compact like Metro bus list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        whenText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: minutesUntil <= 2 ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        arrivalTimeStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (headsign.isNotEmpty)
                    Text(
                      'To $headsign',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (stopName.isNotEmpty)
                    Text(
                      stopName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

