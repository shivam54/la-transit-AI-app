/// Metro combined-route display labels (per metro.net/riding/nextrip/)
/// so we show "14/37" or "35/38" instead of raw "37" vs "14" and avoid user confusion.
String displayRouteLabel(String? routeId) {
  if (routeId == null || routeId.isEmpty) return routeId ?? '';
  final r = routeId.trim().split('-').first.trim();
  const combined = {
    '10': '10/48', '48': '10/48',
    '14': '14/37', '37': '14/37',
    '35': '35/38', '38': '35/38',
    '211': '211/215', '215': '211/215',
    '235': '235/236', '236': '235/236',
    '242': '242/243', '243': '242/243',
    '260': '260/261', '261': '260/261',
    '487': '487/489', '489': '487/489',
    '910': '910/950', '950': '910/950',
  };
  return combined[r] ?? routeId;
}
