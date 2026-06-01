import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const VideoSplashScreen({super.key, required this.nextScreen});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash_screen.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // Navigate to next screen when video finishes
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match your video background
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(), // Loading spinner until video loads
      ),
    );
  }
}