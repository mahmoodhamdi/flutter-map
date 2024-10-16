import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LocationData? _currentLocation;
  List<LatLng> _routePoints = [];
  final List<Marker> _markers = [];
  final String _orsKey =
      '5b3ce3597851110001cf624845863c98eee44a0f91ee3e3ef63fad1a';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSatelliteView = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    try {
      _currentLocation = await location.getLocation();
      setState(() {
        _updateCurrentLocationMarker();
      });
    } catch (e) {
      log('Error getting location: $e');
    }

    location.onLocationChanged.listen((LocationData loc) {
      setState(() {
        _currentLocation = loc;
        _updateCurrentLocationMarker();
      });
    });
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers
          .removeWhere((marker) => marker.key == const Key('currentLocation'));
      _markers.add(
        Marker(
          key: const Key('currentLocation'),
          width: 80.0,
          height: 80.0,
          point:
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    if (_currentLocation == null) return;
    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_orsKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords =
            data['features'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints =
              coords.map((coord) => LatLng(coord[1], coord[0])).toList();
          _markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: end,
              child:
                  const Icon(Icons.location_on, color: Colors.red, size: 40.0),
            ),
          );
        });
      } else {
        _showErrorSnackBar("Failed to get route. Please try again.");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred while fetching the route.");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _addDestinationMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      );
    });
    final start =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    _getRoute(start, point);
  }

  void _searchLocation(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final response = await http.get(
          Uri.parse(
              'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _searchResults = data
                .map((item) => {
                      'name': item['display_name'],
                      'lat': double.parse(item['lat']),
                      'lon': double.parse(item['lon']),
                    })
                .toList();
          });
        } else {
          _showErrorSnackBar("Failed to search location. Please try again.");
        }
      } catch (e) {
        _showErrorSnackBar("An error occurred during the search.");
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final LatLng point = LatLng(result['lat'], result['lon']);
    _mapController.move(point, 15.0);
    _addDestinationMarker(point);
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Map'),
        actions: [
          IconButton(
            icon: Icon(_isSatelliteView ? Icons.map : Icons.satellite),
            onPressed: () =>
                setState(() => _isSatelliteView = !_isSatelliteView),
            tooltip: 'Toggle Satellite View',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults.clear());
                        },
                      ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _searchLocation,
            ),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    title: Text(result['name']),
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
            )
          else
            Expanded(
              child: _currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(_currentLocation!.latitude!,
                            _currentLocation!.longitude!),
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) =>
                            _addDestinationMarker(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _isSatelliteView
                              ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
                              : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        ),
                        MarkerClusterLayerWidget(
                          options: MarkerClusterLayerOptions(
                            maxClusterRadius: 120,
                            size: const Size(40, 40),
                            markers: _markers,
                            builder: (context, markers) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    markers.length.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.0,
                               gradientColors: [
                                const Color(0xffE40303),
                                const Color(0xffFF8C00),
                                const Color(0xffFFED00),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.my_location),
            label: 'Go to My Location',
            onTap: () {
              if (_currentLocation != null) {
                _mapController.move(
                  LatLng(_currentLocation!.latitude!,
                      _currentLocation!.longitude!),
                  15.0,
                );
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.clear),
            label: 'Clear Markers',
            onTap: () {
              setState(() {
                _markers.clear();
                _routePoints.clear();
                _updateCurrentLocationMarker();
              });
            },
          ),
        ],
      ),
    );
  }
}
