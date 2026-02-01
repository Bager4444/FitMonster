#!/usr/bin/env python3
"""
Простой анализатор видео для демонстрации
Создает детальный отчет о выполнении упражнений без использования ML библиотек
"""

import json
import os
from datetime import datetime
import random

def analyze_video_demo(video_path="video_2026-01-18_12-24-03.mp4", exercise_type="squat"):
    """
    Демонстрационный анализ видео с имитацией ML обработки
    """
    print(f"🎥 Анализируем видео: {video_path}")
    print(f"🏋️ Тип упражнения: {exercise_type}")
    
    # Проверяем существование файла
    if not os.path.exists(video_path):
        print(f"⚠️ Видеофайл не найден, создаем демо-анализ")
        video_exists = False
    else:
        print(f"✅ Видеофайл найден")
        video_exists = True
    
    # Имитируем анализ
    print("📊 Выполняем анализ техники...")
    
    # Генерируем реалистичные данные анализа
    if exercise_type == "squat":
        analysis_data = generate_squat_analysis(video_exists)
    elif exercise_type == "pushup":
        analysis_data = generate_pushup_analysis(video_exists)
    else:
        analysis_data = generate_generic_analysis(video_exists, exercise_type)
    
    # Сохраняем результаты
    output_file = "flutter_analysis_report.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(analysis_data, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Результаты сохранены в {output_file}")
    
    # Выводим краткий отчет
    print_analysis_summary(analysis_data)
    
    return analysis_data

def generate_squat_analysis(video_exists=True):
    """Генерирует анализ приседаний"""
    base_score = random.uniform(75, 95) if video_exists else random.uniform(80, 90)
    
    # Генерируем углы с реалистичными значениями
    knee_min = random.uniform(75, 95)  # Минимальный угол в приседе
    knee_max = random.uniform(160, 175)  # Максимальный угол стоя
    knee_range = knee_max - knee_min
    
    # Определяем качество на основе углов
    depth_quality = "excellent" if knee_min < 90 else "good" if knee_min < 110 else "poor"
    
    errors = []
    recommendations = []
    
    # Анализируем глубину
    if knee_min < 85:
        recommendations.append("✅ Отличная глубина приседания!")
        base_score += 5
    elif knee_min < 100:
        recommendations.append("👍 Хорошая глубина приседания")
    else:
        errors.append("Недостаточная глубина приседания")
        recommendations.append("💡 Приседайте глубже, до угла 90° в коленях")
        base_score -= 10
    
    # Случайные дополнительные замечания
    if random.random() < 0.3:
        errors.append("Небольшое отклонение коленей внутрь")
        recommendations.append("💡 Следите за положением коленей - направляйте их в сторону носков")
        base_score -= 5
    
    if random.random() < 0.4:
        recommendations.append("👍 Отличная стабильность торса")
        base_score += 3
    
    if random.random() < 0.2:
        errors.append("Слишком быстрое выполнение")
        recommendations.append("💡 Выполняйте упражнение медленнее для лучшего контроля")
        base_score -= 8
    
    # Всегда добавляем позитивные моменты
    recommendations.append("✅ Хорошая техника выполнения")
    
    return {
        "video_file": "video_2026-01-18_12-24-03.mp4",
        "exercise_type": "squat",
        "analysis_date": datetime.now().isoformat(),
        "quality_score": round(max(60, min(100, base_score)), 1),
        "total_frames": random.randint(40, 60),
        "duration": round(random.uniform(3.0, 5.0), 1),
        "key_metrics": {
            "knee_min_angle": round(knee_min, 1),
            "knee_max_angle": round(knee_max, 1),
            "knee_range": round(knee_range, 1),
            "depth_quality": depth_quality,
            "stability_score": round(random.uniform(85, 95), 1),
            "speed_consistency": round(random.uniform(80, 92), 1)
        },
        "errors": errors,
        "recommendations": recommendations,
        "phases": [
            {
                "phase": "descent",
                "duration_frames": random.randint(18, 28),
                "quality": "excellent" if base_score > 85 else "good",
                "angle_change": round(knee_range * 0.9, 1),
                "speed": "optimal"
            },
            {
                "phase": "ascent",
                "duration_frames": random.randint(18, 28),
                "quality": "good",
                "angle_change": round(knee_range * 0.95, 1),
                "speed": "optimal" if base_score > 80 else "slightly_fast"
            }
        ],
        "detailed_analysis": {
            "repetitions_detected": random.randint(2, 4),
            "average_rep_duration": round(random.uniform(1.2, 1.8), 2),
            "consistency_score": round(random.uniform(85, 95), 1),
            "form_breakdown": {
                "knee_tracking": round(random.uniform(80, 95), 1),
                "hip_hinge": round(random.uniform(85, 95), 1),
                "torso_angle": round(random.uniform(82, 92), 1),
                "depth_consistency": round(random.uniform(88, 96), 1)
            },
            "improvement_areas": [area for area in ["Контроль коленей", "Пауза в нижней точке", "Скорость выполнения"] if random.random() < 0.4],
            "strengths": ["Отличная глубина", "Хорошая стабильность торса", "Правильная техника"]
        },
        "vector_analysis": {
            "hip_to_knee_vector": {
                "consistency": round(random.uniform(88, 95), 1),
                "optimal_angle_maintained": True
            },
            "knee_to_ankle_vector": {
                "consistency": round(random.uniform(85, 93), 1),
                "forward_lean_detected": False
            },
            "torso_stability": {
                "score": round(random.uniform(90, 96), 1),
                "excessive_forward_lean": False
            }
        }
    }

def generate_pushup_analysis(video_exists=True):
    """Генерирует анализ отжиманий"""
    base_score = random.uniform(70, 90) if video_exists else random.uniform(75, 88)
    
    elbow_min = random.uniform(70, 100)
    elbow_max = random.uniform(160, 180)
    
    errors = []
    recommendations = []
    
    if elbow_min < 90:
        recommendations.append("✅ Отличная глубина отжимания!")
        base_score += 8
    else:
        errors.append("Недостаточная глубина отжимания")
        recommendations.append("💡 Опускайтесь ниже, до угла 90° в локтях")
        base_score -= 12
    
    recommendations.append("💪 Отжимания - отличное упражнение для верха тела!")
    
    return {
        "video_file": "video_2026-01-18_12-24-03.mp4",
        "exercise_type": "pushup",
        "analysis_date": datetime.now().isoformat(),
        "quality_score": round(max(60, min(100, base_score)), 1),
        "total_frames": random.randint(35, 55),
        "duration": round(random.uniform(2.5, 4.5), 1),
        "key_metrics": {
            "elbow_min_angle": round(elbow_min, 1),
            "elbow_max_angle": round(elbow_max, 1),
            "elbow_range": round(elbow_max - elbow_min, 1),
            "form_stability": round(random.uniform(80, 92), 1)
        },
        "errors": errors,
        "recommendations": recommendations,
        "phases": [
            {
                "phase": "descent",
                "duration_frames": random.randint(15, 25),
                "quality": "good",
                "speed": "optimal"
            },
            {
                "phase": "ascent",
                "duration_frames": random.randint(15, 25),
                "quality": "good",
                "speed": "optimal"
            }
        ],
        "detailed_analysis": {
            "repetitions_detected": random.randint(2, 5),
            "consistency_score": round(random.uniform(80, 92), 1),
            "strengths": ["Хорошая стабильность корпуса", "Правильная техника рук"]
        }
    }

def generate_generic_analysis(video_exists=True, exercise_type="unknown"):
    """Генерирует общий анализ для любого упражнения"""
    base_score = random.uniform(75, 88)
    
    return {
        "video_file": "video_2026-01-18_12-24-03.mp4",
        "exercise_type": exercise_type,
        "analysis_date": datetime.now().isoformat(),
        "quality_score": round(base_score, 1),
        "total_frames": random.randint(30, 50),
        "duration": round(random.uniform(2.0, 4.0), 1),
        "key_metrics": {
            "overall_form": round(random.uniform(75, 90), 1),
            "consistency": round(random.uniform(80, 92), 1)
        },
        "errors": [],
        "recommendations": [
            "👍 Хорошая техника выполнения",
            "💡 Продолжайте тренироваться",
            "✅ Следите за правильной формой"
        ],
        "phases": [],
        "detailed_analysis": {
            "repetitions_detected": random.randint(1, 3),
            "consistency_score": round(random.uniform(75, 88), 1),
            "strengths": ["Стабильное выполнение"]
        }
    }

def print_analysis_summary(data):
    """Выводит краткий отчет анализа"""
    print(f"\n🎯 РЕЗУЛЬТАТЫ АНАЛИЗА:")
    print(f"   Упражнение: {data['exercise_type']}")
    print(f"   Общая оценка: {data['quality_score']}/100")
    print(f"   Длительность: {data['duration']}с")
    print(f"   Кадров: {data['total_frames']}")
    
    if data.get('key_metrics'):
        print(f"\n📊 КЛЮЧЕВЫЕ МЕТРИКИ:")
        for key, value in data['key_metrics'].items():
            if isinstance(value, (int, float)):
                print(f"   {key}: {value}")
            else:
                print(f"   {key}: {value}")
    
    if data.get('errors'):
        print(f"\n⚠️ ОШИБКИ:")
        for error in data['errors']:
            print(f"   • {error}")
    
    if data.get('recommendations'):
        print(f"\n💡 РЕКОМЕНДАЦИИ:")
        for rec in data['recommendations']:
            print(f"   {rec}")
    
    # Итоговая оценка
    score = data['quality_score']
    if score >= 90:
        print(f"\n🏆 ОТЛИЧНОЕ ВЫПОЛНЕНИЕ!")
    elif score >= 75:
        print(f"\n👍 ХОРОШЕЕ ВЫПОЛНЕНИЕ!")
    elif score >= 60:
        print(f"\n⚠️ УДОВЛЕТВОРИТЕЛЬНО")
    else:
        print(f"\n❌ ТРЕБУЕТ УЛУЧШЕНИЯ")

if __name__ == "__main__":
    # Можно запустить с параметрами или без
    import sys
    
    video_file = sys.argv[1] if len(sys.argv) > 1 else "video_2026-01-18_12-24-03.mp4"
    exercise = sys.argv[2] if len(sys.argv) > 2 else "squat"
    
    print("🚀 Запуск простого анализатора видео...")
    analyze_video_demo(video_file, exercise)
    print("✅ Анализ завершен!")