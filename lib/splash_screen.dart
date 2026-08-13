import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'theme.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key, required this.nextScreen});

  final Widget nextScreen;

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;
  bool _failedToLoad = false;
  // `mounted` is not enough: initialize() and play() can resolve after the
  // fallback timer has already navigated away and disposed the controller.
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash_screen.mp4')
      ..setLooping(false)
      ..addListener(_videoListener);
    _initializeVideo();
    _fallbackTimer = Timer(const Duration(seconds: 8), _continueToApp);
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (!mounted || _disposed) return;
      setState(() {});
      if (_disposed) return;
      await _controller.play();
    } catch (_) {
      if (!mounted || _disposed) return;
      setState(() => _failedToLoad = true);
      Timer(const Duration(milliseconds: 500), _continueToApp);
    }
  }

  void _videoListener() {
    if (_disposed || !_controller.value.isInitialized || _hasNavigated) return;
    final duration = _controller.value.duration;
    if (duration == Duration.zero) return;
    if (_controller.value.position >=
        duration - const Duration(milliseconds: 100)) {
      _continueToApp();
    }
  }

  void _continueToApp() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _fallbackTimer?.cancel();
    _controller
      ..removeListener(_videoListener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreenDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Center(
              child: Image.asset('assets/icon.png', width: 96, height: 96),
            ),
          if (!_controller.value.isInitialized && !_failedToLoad)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: Center(
                child: CupertinoActivityIndicator(
                  color: AppTheme.textOnPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
