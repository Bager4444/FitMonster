import 'package:flutter/material.dart';

/// Индикатор фазы повторения
class RepPhaseIndicator extends StatelessWidget {
  final bool isInDownPosition;
  final String feedback;
  
  const RepPhaseIndicator({
    super.key,
    required this.isInDownPosition,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getPhaseColor().withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getPhaseColor().withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPhaseIcon(),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feedback,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getPhaseColor() {
    if (feedback.contains('Повторение')) {
      return Colors.green;
    } else if (isInDownPosition) {
      return Colors.orange;
    } else if (feedback.contains('Встаньте') || feedback.contains('Улучшите')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }
  
  IconData _getPhaseIcon() {
    if (feedback.contains('Повторение')) {
      return Icons.check_circle;
    } else if (isInDownPosition) {
      return Icons.arrow_upward;
    } else if (feedback.contains('Встаньте') || feedback.contains('Улучшите')) {
      return Icons.warning;
    } else {
      return Icons.fitness_center;
    }
  }
}
