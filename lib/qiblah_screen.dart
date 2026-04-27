import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({super.key});

  @override
  State<QiblahScreen> createState() => _QiblahScreenState();
}

class _QiblahScreenState extends State<QiblahScreen> {
  bool _hasPermission = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

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

  Future<void> _getLocation() async {
    // FIX: Using the new LocationSettings instead of deprecated desiredAccuracy
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    // FIX: Guarding the async gap with mounted check
    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _hasPermission = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Standard context.watch for cleaner provider access
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Qiblat Finder", "Pencari Kiblat")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: !_hasPermission || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final direction = snapshot.data!;
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

                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            // FIX: Replaced withOpacity with withValues
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12), 
                              blurRadius: 15
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lang.getText("Your Location", "Lokasi Anda"), style: const TextStyle(color: Colors.grey)),
                                const Text("Kuala Lumpur", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lang.getText("Distance to Kaabah", "Jarak ke Kaabah")),
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