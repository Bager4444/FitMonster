import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для работы с локальным хранилищем файлов
class StorageService {
  /// Сохранить фото профиля локально
  Future<String?> saveProfilePhoto({
    required String userId,
    required File file,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profiles/$userId');
      
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${profileDir.path}/$fileName');
      
      await file.copy(savedFile.path);
      
      // Сохраняем путь в Hive
      await HiveService.put(
        box: HiveService.userBox,
        key: 'profile_photo_$userId',
        value: savedFile.path,
      );
      
      print('✅ Profile photo saved locally: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      print('❌ Error saving profile photo: $e');
      return null;
    }
  }
  
  /// Получить путь к фото профиля
  Future<String?> getProfilePhotoPath(String userId) async {
    try {
      final path = HiveService.get(
        box: HiveService.userBox,
        key: 'profile_photo_$userId',
      ) as String?;
      
      if (path != null && await File(path).exists()) {
        return path;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting profile photo path: $e');
      return null;
    }
  }
  
  /// Конвертировать фото в base64 для хранения в Hive
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
  
  /// Конвертировать base64 обратно в байты
  static List<int> base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

  /// Сохранить фото тренировки
  Future<String?> saveWorkoutPhoto({
    required String userId,
    required String workoutId,
    required File file,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final workoutDir = Directory('${directory.path}/workouts/$userId/$workoutId');
      
      if (!await workoutDir.exists()) {
        await workoutDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'workout_$timestamp.jpg';
      final savedFile = File('${workoutDir.path}/$fileName');
      
      await file.copy(savedFile.path);
      
      print('✅ Workout photo saved: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      print('❌ Error saving workout photo: $e');
      return null;
    }
  }

  /// Удалить файл
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ File deleted: $filePath');
      }
    } catch (e) {
      print('❌ Error deleting file: $e');
    }
  }
  
  /// Очистить все фото пользователя
  Future<void> clearUserPhotos(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final userDir = Directory('${directory.path}/profiles/$userId');
      final workoutDir = Directory('${directory.path}/workouts/$userId');
      
      if (await userDir.exists()) {
        await userDir.delete(recursive: true);
      }
      
      if (await workoutDir.exists()) {
        await workoutDir.delete(recursive: true);
      }
      
      // Удаляем запись из Hive
      await HiveService.delete(
        box: HiveService.userBox,
        key: 'profile_photo_$userId',
      );
      
      print('✅ User photos cleared for: $userId');
    } catch (e) {
      print('❌ Error clearing user photos: $e');
    }
  }
}
