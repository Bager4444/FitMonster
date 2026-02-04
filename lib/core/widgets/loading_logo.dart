import 'package:flutter/material.dart';

/// Индикатор загрузки по центру экрана.
class LoadingLogo extends StatelessWidget {
  const LoadingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF38BDF8),
        strokeWidth: 2.5,
      ),
    );
  }
}
