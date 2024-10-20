import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> history;

  const HistoryScreen({super.key, required this.history});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  LocationData? _currentLocation;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      log("Error getting location: $e");
    }
  }

  String _getLocationName(Map<String, dynamic> item) {
    if (item['type'] == 'search') {
      return item['name'];
    } else {
      return 'Route: ${item['start']['name']} to ${item['end']['name']}';
    }
  }

  String _getDistanceString(Map<String, dynamic> item) {
    if (_currentLocation == null) {
      return 'Calculating...';
    }

    const Distance distance = Distance();
    double distanceInMeters;

    if (item['type'] == 'search') {
      distanceInMeters = distance.as(
        LengthUnit.Meter,
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        LatLng(item['lat'], item['lon']),
      );
    } else {
      distanceInMeters = distance.as(
        LengthUnit.Meter,
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        LatLng(item['end']['lat'], item['end']['lon']),
      );
    }

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search and Route History'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: widget.history.isEmpty
          ? Center(
              child: Text("No history available.",
                  style: TextStyle(fontSize: 18, color: Colors.grey[700])))
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                final item = widget.history[index];
                final icon =
                    item['type'] == 'search' ? Icons.search : Icons.directions;
                final locationName = _getLocationName(item);
                final distance = _getDistanceString(item);
                final dateTime = DateTime.parse(item['timestamp']);
                final formattedDate =
                    DateFormat('MMM d, y HH:mm').format(dateTime);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(icon, color: Colors.white),
                    ),
                    title: Text(locationName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(distance, style: const TextStyle(fontSize: 16)),
                        Text(formattedDate,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.history.removeAt(index);
                        });
                      },
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
    );
  }
}
