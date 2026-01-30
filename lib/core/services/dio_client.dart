import 'package:dio/dio.dart';

/// Настроенный Dio клиент для HTTP запросов
class DioClient {
  static Dio? _instance;
  
  /// Получить singleton экземпляр Dio
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'FitMonster/1.0 (fitness app; contact@fitmonster.app)',
        'Accept': 'application/json',
      },
    ));

    // Логирование (только в debug режиме)
    assert(() {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => print('🌐 DIO: $obj'),
      ));
      return true;
    }());

    // Interceptor для обработки ошибок
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print('❌ DIO Error: ${error.type} - ${error.message}');
        
        // Можно добавить retry логику здесь
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          print('⏱️ Timeout error, consider retry');
        }
        
        handler.next(error);
      },
    ));

    return dio;
  }

  /// Сбросить клиент (для тестов)
  static void reset() {
    _instance?.close();
    _instance = null;
  }
}
