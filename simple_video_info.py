#!/usr/bin/env python3
"""
Простой анализатор видео без зависимостей
Показывает базовую информацию о видеофайле
"""

import os
import sys

def analyze_video_file(video_path):
    """Анализирует видеофайл и показывает базовую информацию"""
    
    print(f"🎥 Анализ видеофайла: {video_path}")
    print("=" * 50)
    
    # Проверяем существование файла
    if not os.path.exists(video_path):
        print(f"❌ Файл {video_path} не найден!")
        return False
    
    # Получаем размер файла
    file_size = os.path.getsize(video_path)
    file_size_mb = file_size / (1024 * 1024)
    
    print(f"📁 Размер файла: {file_size_mb:.2f} MB ({file_size:,} bytes)")
    
    # Получаем расширение
    _, ext = os.path.splitext(video_path)
    print(f"📄 Формат: {ext.upper()}")
    
    # Время создания/изменения
    import time
    mtime = os.path.getmtime(video_path)
    mtime_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(mtime))
    print(f"📅 Дата изменения: {mtime_str}")
    
    print("\n🔍 Для полного анализа поз необходимо установить:")
    print("  pip install opencv-python mediapipe matplotlib numpy")
    print("\n💡 После установки зависимостей запустите:")
    print("  python video_pose_analyzer.py")
    
    return True

def main():
    video_file = 'video_2026-01-18_12-24-03.mp4'
    
    print("🎯 Простой анализатор видео")
    print("Создан для FitMonster приложения\n")
    
    if analyze_video_file(video_file):
        print(f"\n✅ Базовый анализ {video_file} завершен!")
        print("\n📋 Что можно сделать с этим видео:")
        print("  1. Использовать как эталон для упражнений")
        print("  2. Извлечь ключевые точки поз")
        print("  3. Создать 3D траектории движения")
        print("  4. Сравнить с выполнением пользователей")
        print("  5. Настроить пороги для подсчета повторений")
    else:
        print("\n❌ Не удалось проанализировать видео")

if __name__ == "__main__":
    main()