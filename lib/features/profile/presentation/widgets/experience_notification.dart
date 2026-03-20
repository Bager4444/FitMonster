import 'package:flutter/material.dart';

/// Показывает уведомление о начисленном опыте.
void showExperienceNotification(BuildContext context, int experienceGained) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('+$experienceGained опыт'),
      duration: const Duration(seconds: 2),
    ),
  );
}
