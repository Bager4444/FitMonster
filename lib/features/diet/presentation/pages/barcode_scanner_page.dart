import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/features/diet/data/repositories/food_repository.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_detail_page.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

/// Страница сканирования штрих-кода
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late final FoodRepository _foodRepo;
  final _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _foodRepo = context.read<FoodRepository>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    // Избежать повторной обработки того же кода
    if (_lastScannedCode == barcode.rawValue) return;
    _lastScannedCode = barcode.rawValue;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Поиск продукта по штрих-коду (гибридный: local + API)
      final result = await _foodRepo.findByBarcode(barcode.rawValue!);

      if (!mounted) return;

      if (result.isNotEmpty) {
        // Продукт найден - показать детали
        final food = result.first!;
        _controller.stop();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailPage(
              foodId: food.id,
              food: food,
            ),
          ),
        );
      } else if (result.isOffline) {
        // Офлайн режим - продукт не найден локально
        _showOfflineMessage(barcode.rawValue!);
      } else {
        // Продукт не найден ни локально, ни в API
        _showProductNotFound(barcode.rawValue!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showProductNotFound(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Продукт не найден'),
        content: Text(
          'Штрих-код $barcode не найден ни в локальной базе, ни в онлайн-каталоге.\n\n'
          'Попробуйте добавить продукт вручную через поиск.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _lastScannedCode = null; // Разрешить повторное сканирование
            },
            child: const Text('Продолжить сканирование'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showOfflineMessage(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.wifi_off, size: 48, color: Colors.orange[700]),
        title: const Text('Нет интернета'),
        content: Text(
          'Штрих-код $barcode не найден в локальной базе.\n\n'
          'Подключитесь к интернету для поиска в онлайн-каталоге Open Food Facts.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _lastScannedCode = null; // Разрешить повторное сканирование
            },
            child: const Text('Попробовать снова'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование штрих-кода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Включить/выключить вспышку',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Переключить камеру',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          // Overlay с инструкциями
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Наведите камеру на штрих-код продукта',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Поиск в локальной базе и Open Food Facts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Индикатор обработки
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Поиск продукта...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
