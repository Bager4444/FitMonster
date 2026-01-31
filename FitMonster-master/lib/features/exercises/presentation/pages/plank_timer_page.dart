import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:async';

class PlankTimerPage extends StatefulWidget {
  const PlankTimerPage({super.key});

  @override
  State<PlankTimerPage> createState() => _PlankTimerPageState();
}

class _PlankTimerPageState extends State<PlankTimerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plank Timer')),
      body: const Center(child: Text('Plank Timer Placeholder')),
    );
  }
}