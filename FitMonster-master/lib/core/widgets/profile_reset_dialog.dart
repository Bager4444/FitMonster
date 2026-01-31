import 'package:flutter/material.dart';
import 'package:fitmonster/core/services/profile_reset_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';

/// Диалог для создания нулевого профиля
class ProfileResetDialog extends StatefulWidget {
  final String userId;
  final Function(UserProfile)? onProfileCreated;

  const ProfileResetDialog({
    super.key,
    required this.userId,
    this.onProfileCreated,
  });

  @override
  State<ProfileResetDialog> createState() => _ProfileResetDialogState();
}

class _ProfileResetDialogState extends State<ProfileResetDialog> {
  final ProfileResetService _resetService = ProfileResetService();
  bool _isCreating = false;
  String _selectedType = 'zero'; // 'zero', 'absolute', 'template'

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Создать профиль'),
        ],
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_isCreating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Создается профиль...'),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите тип профиля:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        
        _buildProfileOption(
          'zero',
          'Минимальный профиль',
          'Возраст: 18, Рост: 150см, Вес: 40кг',
          Icons.person_outline,
          Colors.green,
        ),
        
        _buildProfileOption(
          'absolute',
          'Абсолютный ноль',
          'Все значения равны нулю',
          Icons.exposure_zero,
          Colors.orange,
        ),
        
        _buildProfileOption(
          'template',
          'Шаблон профиля',
          'Стандартные значения для заполнения',
          Icons.person,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_isCreating) {
      return [];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        onPressed: _createProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: const Text('Создать'),
      ),
    ];
  }

  Future<void> _createProfile() async {
    setState(() {
      _isCreating = true;
    });

    try {
      UserProfile profile;
      
      switch (_selectedType) {
        case 'zero':
          profile = await _resetService.createZeroProfile(widget.userId);
          break;
        case 'absolute':
          profile = await _resetService.createAbsoluteZeroProfile(widget.userId);
          break;
        case 'template':
          profile = await _resetService.createTemplateProfile(widget.userId);
          break;
        default:
          profile = await _resetService.createZeroProfile(widget.userId);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно создан'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Вызываем callback
        widget.onProfileCreated?.call(profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании профиля: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Показать диалог создания профиля
  static Future<void> show({
    required BuildContext context,
    required String userId,
    Function(UserProfile)? onProfileCreated,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProfileResetDialog(
          userId: userId,
          onProfileCreated: onProfileCreated,
        );
      },
    );
  }
}