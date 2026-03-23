import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

class CustomRoute {
  final String name;
  final Color color;
  final List<LatLng> stops;
  List<LatLng> polyline = [];

  CustomRoute({required this.name, required this.color, required this.stops});

  Future<void> buildPolyline() async {
    final service = RoutingService();
    List<LatLng> fullRoute = [];
    for (int i = 0; i < stops.length - 1; i++) {
      final segment = await service.getRoute(stops[i], stops[i + 1]);
      fullRoute.addAll(segment);
    }
    polyline = fullRoute;
  }
}
