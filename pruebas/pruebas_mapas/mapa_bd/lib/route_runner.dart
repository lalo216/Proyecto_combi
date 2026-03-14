import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteRunner {
  final List<LatLng> routePoints;
  final Duration stepDuration;
  int _currentIndex = 0;
  LatLng? currentPosition;
  Timer? _timer;

  RouteRunner({
    required this.routePoints,
    this.stepDuration = const Duration(seconds: 1),
  });

  void start(VoidCallback onUpdate) {
    _currentIndex = 0;
    currentPosition = routePoints.isNotEmpty ? routePoints.first : null;
    _timer = Timer.periodic(stepDuration, (timer) {
      if (_currentIndex < routePoints.length) {
        currentPosition = routePoints[_currentIndex];
        _currentIndex++;
        onUpdate();
      } else {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
