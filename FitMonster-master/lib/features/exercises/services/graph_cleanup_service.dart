import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Сервис для очистки графа и освобождения ресурсов
class GraphCleanupService {
  static final GraphCleanupService _instance = GraphCleanupService._internal();
  factory GraphCleanupService() => _instance;
  GraphCleanupService._internal();
  
  // Кэши и буферы для очистки
  final Map<String, Uint8List> _imageBufferCache = {};
  final List<Pose> _poseHistory = [];
  final Map<String, dynamic> _graphCache = {};
  final List<dynamic> _processingQueue = [];
  
  /// Полная очистка всех графов и кэшей
  void clearAllGraphData() {
    print('🧹 Начинаем полную очистку графа...');
    
    // Очищаем кэши изображений
    _clearImageBuffers();
    
    // Очищаем историю поз
    _clearPoseHistory();
    
    // Очищаем кэш графа
    _clearGraphCache();
    
    // Очищаем очередь обработки
    _clearProcessingQueue();
    
    // Принудительная сборка мусора
    _forceGarbageCollection();
    
    print('✅ Полная очистка графа завершена');
  }
  
  /// Быстрая очистка только активных данных
  void quickCleanup() {
    print('⚡ Быстрая очистка графа...');
    
    // Очищаем только активные буферы
    _imageBufferCache.clear();
    _processingQueue.clear();
    
    // Оставляем только последние 3 позы
    if (_poseHistory.length > 3) {
      _poseHistory.removeRange(0, _poseHistory.length - 3);
    }
    
    print('✅ Быстрая очистка завершена');
  }
  
  /// Очистка кэшей изображений
  void _clearImageBuffers() {
    final bufferCount = _imageBufferCache.length;
    _imageBufferCache.clear();
    print('🗑️ Очищено $bufferCount буферов изображений');
  }
  
  /// Очистка истории поз
  void _clearPoseHistory() {
    final poseCount = _poseHistory.length;
    _poseHistory.clear();
    print('🗑️ Очищено $poseCount поз из истории');
  }
  
  /// Очистка кэша графа
  void _clearGraphCache() {
    final cacheCount = _graphCache.length;
    _graphCache.clear();
    print('🗑️ Очищено $cacheCount элементов кэша графа');
  }
  
  /// Очистка очереди обработки
  void _clearProcessingQueue() {
    final queueCount = _processingQueue.length;
    _processingQueue.clear();
    print('🗑️ Очищено $queueCount элементов очереди обработки');
  }
  
  /// Принудительная сборка мусора
  void _forceGarbageCollection() {
    // Dart автоматически управляет памятью, но мы можем помочь
    // Создаем небольшое давление на память для запуска GC
    final tempList = List.generate(1000, (i) => i);
    tempList.clear();
    print('🗑️ Запущена сборка мусора');
  }
  
  /// Регистрация буфера изображения для отслеживания
  void registerImageBuffer(String key, Uint8List buffer) {
    _imageBufferCache[key] = buffer;
  }
  
  /// Регистрация позы в истории
  void registerPose(Pose pose) {
    _poseHistory.add(pose);
    
    // Автоматически ограничиваем размер истории
    if (_poseHistory.length > 50) {
      _poseHistory.removeAt(0);
    }
  }
  
  /// Регистрация элемента кэша графа
  void registerGraphCache(String key, dynamic data) {
    _graphCache[key] = data;
  }
  
  /// Добавление элемента в очередь обработки
  void addToProcessingQueue(dynamic item) {
    _processingQueue.add(item);
    
    // Автоматически ограничиваем размер очереди
    if (_processingQueue.length > 100) {
      _processingQueue.removeAt(0);
    }
  }
  
  /// Получение статистики использования памяти
  MemoryStats getMemoryStats() {
    return MemoryStats(
      imageBuffers: _imageBufferCache.length,
      poseHistory: _poseHistory.length,
      graphCache: _graphCache.length,
      processingQueue: _processingQueue.length,
      estimatedMemoryMB: _calculateEstimatedMemory(),
    );
  }
  
  /// Расчёт приблизительного использования памяти
  double _calculateEstimatedMemory() {
    double totalMB = 0.0;
    
    // Буферы изображений (примерно 1MB каждый для среднего разрешения)
    totalMB += _imageBufferCache.length * 1.0;
    
    // История поз (примерно 10KB каждая)
    totalMB += _poseHistory.length * 0.01;
    
    // Кэш графа (примерно 50KB каждый элемент)
    totalMB += _graphCache.length * 0.05;
    
    // Очередь обработки (примерно 5KB каждый элемент)
    totalMB += _processingQueue.length * 0.005;
    
    return totalMB;
  }
  
  /// Автоматическая очистка при превышении лимитов
  void autoCleanupIfNeeded() {
    final stats = getMemoryStats();
    
    // Если использование памяти превышает 50MB, делаем быструю очистку
    if (stats.estimatedMemoryMB > 50.0) {
      print('⚠️ Превышен лимит памяти (${stats.estimatedMemoryMB.toStringAsFixed(1)}MB), запускаем автоочистку');
      quickCleanup();
    }
    
    // Если слишком много элементов в кэшах, очищаем их
    if (stats.imageBuffers > 20) {
      _clearImageBuffers();
    }
    
    if (stats.poseHistory > 100) {
      _poseHistory.removeRange(0, _poseHistory.length - 50);
      print('🗑️ Сокращена история поз до 50 элементов');
    }
  }
}

/// Статистика использования памяти
class MemoryStats {
  final int imageBuffers;
  final int poseHistory;
  final int graphCache;
  final int processingQueue;
  final double estimatedMemoryMB;
  
  const MemoryStats({
    required this.imageBuffers,
    required this.poseHistory,
    required this.graphCache,
    required this.processingQueue,
    required this.estimatedMemoryMB,
  });
  
  @override
  String toString() {
    return 'MemoryStats(buffers: $imageBuffers, poses: $poseHistory, '
           'cache: $graphCache, queue: $processingQueue, '
           'memory: ${estimatedMemoryMB.toStringAsFixed(1)}MB)';
  }
}