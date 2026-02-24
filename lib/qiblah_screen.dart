import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart'; // Add this to your pubspec.yaml
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({super.key});

  @override
  State<QiblahScreen> createState() => _QiblahScreenState();
}

class _QiblahScreenState extends State<QiblahScreen> {
  bool _hasPermission = false;
  Position? _currentPosition; // To store the coordinates

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  // Math: Haversine Formula
  double _calculateDistance(double lat1, double lon1) {
    const double kaabahLat = 21.4225;
    const double kaabahLon = 39.8262;
    const double earthRadius = 6371;

    double dLat = (kaabahLat - lat1) * (math.pi / 180);
    double dLon = (kaabahLon - lon1) * (math.pi / 180);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(kaabahLat * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _checkAndRequestPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      _getLocation();
    } else {
      var result = await Permission.location.request();
      if (result.isGranted) _getLocation();
    }
  }

  // Fetch the actual GPS coordinates
  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    setState(() {
      _currentPosition = position;
      _hasPermission = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Qiblah Finder")),
      body: !_hasPermission || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final direction = snapshot.data!;
                // Use the position we fetched in _getLocation()
                final distance = _calculateDistance(
                    _currentPosition!.latitude, _currentPosition!.longitude);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Text(
                        "${direction.qiblah.toStringAsFixed(0)}°",
                        style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 30),
                      
                      // Compass Logic
                      Center(
                        child: SizedBox(
                          height: 250,
                          width: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.circle_outlined, size: 250, color: Colors.grey),
                              Transform.rotate(
                                angle: (direction.qiblah * (math.pi / 180) * -1),
                                child: const Icon(Icons.navigation, size: 120, color: AppTheme.accentGold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),

                      // Information Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Your Location", style: TextStyle(color: Colors.grey)),
                                Text("Kuala Lumpur", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Distance to Kaabah"),
                                Text(
                                  "${distance.toStringAsFixed(0)} KM",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            LinearProgressIndicator(
                              value: 0.8,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              color: AppTheme.accentGold,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}