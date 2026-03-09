import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';

/// Route Provider for managing routes and navigation
class RouteProvider extends ChangeNotifier {
  RouteModel? _currentRoute;
  List<RouteModel> _routeStack = []; // For detour management
  RouteModel? _activeDetour;
  String _selectedTransportMode = 'public_transit'; // 'drive', 'public_transit', 'walk', 'bike', 'ride_share'
  bool _isLoading = false;
  String? _error;

  RouteModel? get currentRoute => _currentRoute;
  List<RouteModel> get routeStack => _routeStack;
  RouteModel? get activeDetour => _activeDetour;
  String get selectedTransportMode => _selectedTransportMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRoute => _currentRoute != null;
  bool get hasActiveDetour => _activeDetour != null;

  /// Set transport mode
  void setTransportMode(String mode) {
    if (['drive', 'public_transit', 'walk', 'bike', 'ride_share'].contains(mode)) {
      _selectedTransportMode = mode;
      notifyListeners();
    }
  }

  /// Set current route
  void setRoute(RouteModel route) {
    _currentRoute = route;
    _error = null;
    notifyListeners();
  }

  /// Start a detour (push current route to stack)
  void startDetour(RouteModel detourRoute) {
    if (_currentRoute != null) {
      _routeStack.add(_currentRoute!);
    }
    _activeDetour = detourRoute;
    _currentRoute = detourRoute;
    notifyListeners();
  }

  /// Resume original route from stack
  void resumeOriginalRoute() {
    if (_routeStack.isNotEmpty) {
      _currentRoute = _routeStack.removeLast();
      _activeDetour = null;
      notifyListeners();
    }
  }

  /// Clear route
  void clearRoute() {
    _currentRoute = null;
    _routeStack.clear();
    _activeDetour = null;
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
}

