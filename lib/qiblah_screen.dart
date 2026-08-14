import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  bool _isLoading = true;
  Position? _currentPosition;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1) {
    const kaabahLat = 21.4225;
    const kaabahLon = 39.8262;
    const earthRadius = 6371.0;
    final dLat = (kaabahLat - lat1) * (math.pi / 180);
    final dLon = (kaabahLon - lon1) * (math.pi / 180);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(kaabahLat * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _checkAndRequestPermission() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _permissionError = null;
      });
    }

    var status = await Permission.location.status;
    if (!status.isGranted) status = await Permission.location.request();

    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionError = status.isPermanentlyDenied
            ? 'Location access is disabled in Settings.'
            : 'Location access is needed to find the Qiblat.';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionError = 'Your current location could not be determined.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgSoftWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText('Qiblat', 'Kiblat'),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lang.getText(
                            'Face the Ka’bah from anywhere',
                            'Menghadap Kaabah dari mana-mana',
                          ),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _QiblatHeaderButton(
                    icon: CupertinoIcons.question_circle_fill,
                    onTap: () => _showCalibrationHelp(lang),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(lang)),
          ],
        ),
      ),
    );
  }


  Future<void> _showCalibrationHelp(LanguageProvider lang) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('Using the compass', 'Menggunakan kompas'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            for (final step in [
              (
                CupertinoIcons.device_phone_portrait,
                lang.getText(
                  'Hold the phone flat, screen facing up.',
                  'Pegang telefon rata, skrin menghadap ke atas.',
                ),
              ),
              (
                CupertinoIcons.arrow_2_circlepath,
                lang.getText(
                  'Move it in a figure of eight a few times to calibrate.',
                  'Gerakkan dalam bentuk angka lapan beberapa kali untuk menentukur.',
                ),
              ),
              (
                CupertinoIcons.wifi_slash,
                lang.getText(
                  'Step away from metal, magnets and speakers — they pull the reading off.',
                  'Jauhi logam, magnet dan pembesar suara — ia mengganggu bacaan.',
                ),
              ),
              (
                CupertinoIcons.location_north_line,
                lang.getText(
                  'Turn until the needle sits on the marker; that is the qiblah.',
                  'Pusing sehingga jarum berada pada penanda; itulah arah kiblat.',
                ),
              ),
            ]) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        step.$1,
                        size: 18,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        step.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 15,
          color: AppTheme.primaryGreen,
        ),
      );
    }
    if (_permissionError != null || _currentPosition == null) {
      return _LocationPermissionCard(
        message: _permissionError!,
        onRetry: _checkAndRequestPermission,
      );
    }

    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      initialData: kDebugMode ? const QiblahDirection(89.5, 22.0, 292.5) : null,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CupertinoActivityIndicator(
              radius: 15,
              color: AppTheme.primaryGreen,
            ),
          );
        }

        final direction = snapshot.data!;
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        final normalizedTurn = ((direction.qiblah + 180) % 360) - 180;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
              sliver: SliverList.list(
                children: [
                  _KaabahTargetCard(bearing: direction.offset),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 17),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      children: [
                        Text(
                          normalizedTurn.abs() < 5
                              ? lang.getText(
                                  'You are facing the Qiblat',
                                  'Anda menghadap Kiblat',
                                )
                              : lang.getText(
                                  'Turn ${normalizedTurn.abs().toStringAsFixed(0)}° ${normalizedTurn > 0 ? 'left' : 'right'}',
                                  'Pusing ${normalizedTurn.abs().toStringAsFixed(0)}°',
                                ),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          normalizedTurn.abs() < 5
                              ? 'Perfectly aligned'
                              : 'Move your phone slowly for best accuracy',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _CompassDial(direction: direction),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: normalizedTurn.abs() < 5
                                ? AppTheme.mint
                                : AppTheme.warmCream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                normalizedTurn.abs() < 5
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.rotate_right,
                                color: normalizedTurn.abs() < 5
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFF96742D),
                                size: 15,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                normalizedTurn.abs() < 5
                                    ? 'Aligned'
                                    : 'Calibrating',
                                style: TextStyle(
                                  color: normalizedTurn.abs() < 5
                                      ? AppTheme.primaryGreen
                                      : const Color(0xFF80601E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: CupertinoIcons.location_fill,
                          label: lang.getText('Your location', 'Lokasi anda'),
                          value: 'Kuala Lumpur',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: CupertinoIcons.arrow_up_right,
                          label: lang.getText('Distance', 'Jarak'),
                          value: '${distance.toStringAsFixed(0)} km',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.device_phone_portrait,
                          color: AppTheme.primaryGreen,
                          size: 21,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Keep your phone flat and away from metal objects for a more accurate reading.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QiblatHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QiblatHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(42, 42),
      onPressed: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, size: 19, color: AppTheme.primaryGreen),
      ),
    );
  }
}

class _KaabahTargetCard extends StatelessWidget {
  final double bearing;

  const _KaabahTargetCard({required this.bearing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const _KaabahIcon(size: 48),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ka’bah · Makkah',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '21.4225° N, 39.8262° E',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.location_north_fill,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  '${bearing.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final QiblahDirection direction;

  const _CompassDial({required this.direction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      height: 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: direction.direction * math.pi / 180 * -1,
            child: const CustomPaint(
              size: Size.square(284),
              painter: _CompassFacePainter(),
            ),
          ),
          Transform.rotate(
            angle: direction.qiblah * math.pi / 180 * -1,
            child: const SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 15, child: _KaabahIcon(size: 36)),
                  Positioned(top: 52, child: _QiblahNeedle()),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${direction.direction.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const Text(
                  'HEADING',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblahNeedle extends StatelessWidget {
  const _QiblahNeedle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipPath(
          clipper: _NeedleClipper(),
          child: Container(
            width: 22,
            height: 82,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.accentGold, AppTheme.primaryGreen],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeedleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _KaabahIcon extends StatelessWidget {
  final double size;

  const _KaabahIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF121513),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: size * 0.28,
            child: Container(height: size * 0.12, color: AppTheme.accentGold),
          ),
          Positioned(
            right: size * 0.17,
            bottom: 0,
            child: Container(
              width: size * 0.18,
              height: size * 0.38,
              color: const Color(0xFF212723),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassFacePainter extends CustomPainter {
  const _CompassFacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF6F9F7));
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = AppTheme.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var degree = 0; degree < 360; degree += 10) {
      final angle = (degree - 90) * math.pi / 180;
      final isMajor = degree % 30 == 0;
      final start = Offset(
        center.dx + math.cos(angle) * (radius - (isMajor ? 22 : 14)),
        center.dy + math.sin(angle) * (radius - (isMajor ? 22 : 14)),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (radius - 7),
        center.dy + math.sin(angle) * (radius - 7),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = degree == 0
              ? AppTheme.accentGold
              : AppTheme.textSecondary.withValues(alpha: isMajor ? 0.68 : 0.28)
          ..strokeWidth = isMajor ? 2 : 1,
      );
    }

    const labels = <int, String>{0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    for (final entry in labels.entries) {
      final angle = (entry.key - 90) * math.pi / 180;
      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: entry.key == 0
                ? AppTheme.primaryGreen
                : AppTheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final point = Offset(
        center.dx + math.cos(angle) * (radius - 38),
        center.dy + math.sin(angle) * (radius - 38),
      );
      painter.paint(
        canvas,
        point - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPermissionCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LocationPermissionCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppTheme.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.location_slash_fill,
                color: AppTheme.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable location',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
