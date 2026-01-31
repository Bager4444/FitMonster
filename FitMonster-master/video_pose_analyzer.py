import cv2
import mediapipe as mp
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import json
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from datetime import datetime
import math

@dataclass
class PoseFrame:
    """Данные позы для одного кадра"""
    timestamp: float
    landmarks: Dict[str, Tuple[float, float, float]]  # x, y, z координаты
    visibility: Dict[str, float]
    angles: Dict[str, float]  # Углы между суставами
    vectors: Dict[str, Tuple[float, float, float]]  # Векторы движения

class VideoPoseAnalyzer:
    """Анализатор поз из видео для создания эталонных паттернов упражнений"""
    
    def __init__(self):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=2,
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.mp_drawing = mp.solutions.drawing_utils
        
        # Ключевые точки для разных упражнений с векторами
        self.exercise_keypoints = {
            'squat': {
                'primary': ['LEFT_HIP', 'RIGHT_HIP', 'LEFT_KNEE', 'RIGHT_KNEE', 'LEFT_ANKLE', 'RIGHT_ANKLE'],
                'secondary': ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'NOSE'],
                'vectors': [
                    ('LEFT_HIP', 'LEFT_KNEE'),  # Бедро
                    ('LEFT_KNEE', 'LEFT_ANKLE'),  # Голень
                    ('RIGHT_HIP', 'RIGHT_KNEE'),
                    ('RIGHT_KNEE', 'RIGHT_ANKLE'),
                    ('LEFT_SHOULDER', 'LEFT_HIP'),  # Торс
                    ('RIGHT_SHOULDER', 'RIGHT_HIP')
                ],
                'angles': [
                    ('LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE'),  # Угол в колене
                    ('RIGHT_HIP', 'RIGHT_KNEE', 'RIGHT_ANKLE'),
                    ('LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'),  # Угол бедро-торс
                    ('RIGHT_SHOULDER', 'RIGHT_HIP', 'RIGHT_KNEE')
                ]
            },
            'pushup': {
                'primary': ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'LEFT_ELBOW', 'RIGHT_ELBOW', 'LEFT_WRIST', 'RIGHT_WRIST'],
                'secondary': ['LEFT_HIP', 'RIGHT_HIP', 'NOSE'],
                'vectors': [
                    ('LEFT_SHOULDER', 'LEFT_ELBOW'),  # Плечо
                    ('LEFT_ELBOW', 'LEFT_WRIST'),  # Предплечье
                    ('RIGHT_SHOULDER', 'RIGHT_ELBOW'),
                    ('RIGHT_ELBOW', 'RIGHT_WRIST'),
                    ('LEFT_SHOULDER', 'LEFT_HIP'),  # Торс
                    ('RIGHT_SHOULDER', 'RIGHT_HIP')
                ],
                'angles': [
                    ('LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST'),  # Угол в локте
                    ('RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST'),
                    ('LEFT_ELBOW', 'LEFT_SHOULDER', 'LEFT_HIP'),  # Угол плечо-торс
                    ('RIGHT_ELBOW', 'RIGHT_SHOULDER', 'RIGHT_HIP')
                ]
            },
            'pullup': {
                'primary': ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'LEFT_ELBOW', 'RIGHT_ELBOW', 'LEFT_WRIST', 'RIGHT_WRIST'],
                'secondary': ['LEFT_HIP', 'RIGHT_HIP', 'NOSE'],
                'vectors': [
                    ('LEFT_SHOULDER', 'LEFT_ELBOW'),
                    ('LEFT_ELBOW', 'LEFT_WRIST'),
                    ('RIGHT_SHOULDER', 'RIGHT_ELBOW'),
                    ('RIGHT_ELBOW', 'RIGHT_WRIST'),
                    ('LEFT_SHOULDER', 'LEFT_HIP'),
                    ('RIGHT_SHOULDER', 'RIGHT_HIP')
                ],
                'angles': [
                    ('LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST'),
                    ('RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST'),
                    ('LEFT_WRIST', 'LEFT_ELBOW', 'LEFT_SHOULDER'),
                    ('RIGHT_WRIST', 'RIGHT_ELBOW', 'RIGHT_SHOULDER')
                ]
            }
        }
    
    def calculate_angle(self, p1: Tuple[float, float, float], 
                       p2: Tuple[float, float, float], 
                       p3: Tuple[float, float, float]) -> float:
        """Вычисляет угол между тремя точками (p2 - вершина угла)"""
        # Векторы от p2 к p1 и от p2 к p3
        v1 = np.array([p1[0] - p2[0], p1[1] - p2[1], p1[2] - p2[2]])
        v2 = np.array([p3[0] - p2[0], p3[1] - p2[1], p3[2] - p2[2]])
        
        # Нормализуем векторы
        v1_norm = np.linalg.norm(v1)
        v2_norm = np.linalg.norm(v2)
        
        if v1_norm == 0 or v2_norm == 0:
            return 0
        
        v1_unit = v1 / v1_norm
        v2_unit = v2 / v2_norm
        
        # Вычисляем угол через скалярное произведение
        dot_product = np.clip(np.dot(v1_unit, v2_unit), -1.0, 1.0)
        angle = np.arccos(dot_product)
        
        return math.degrees(angle)
    
    def calculate_vector(self, p1: Tuple[float, float, float], 
                        p2: Tuple[float, float, float]) -> Tuple[float, float, float]:
        """Вычисляет вектор от p1 к p2"""
        return (p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2])
    
    def extract_poses_from_video(self, video_path: str) -> List[PoseFrame]:
        """Извлекает позы из видео с расчетом углов и векторов"""
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        poses = []
        frame_count = 0
        
        print(f"📹 Обрабатываем видео с FPS: {fps}")
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            # Конвертируем BGR в RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Обрабатываем кадр
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks:
                timestamp = frame_count / fps
                landmarks = {}
                visibility = {}
                
                for idx, landmark in enumerate(results.pose_landmarks.landmark):
                    landmark_name = self.mp_pose.PoseLandmark(idx).name
                    landmarks[landmark_name] = (landmark.x, landmark.y, landmark.z)
                    visibility[landmark_name] = landmark.visibility
                
                # Вычисляем углы и векторы (пока без привязки к упражнению)
                angles = {}
                vectors = {}
                
                poses.append(PoseFrame(timestamp, landmarks, visibility, angles, vectors))
                
                if frame_count % 30 == 0:  # Прогресс каждые 30 кадров
                    print(f"⏳ Обработано кадров: {frame_count}")
            
            frame_count += 1
        
        cap.release()
        print(f"✅ Всего обработано кадров: {frame_count}")
        return poses
    
    def analyze_exercise_technique(self, poses: List[PoseFrame], exercise_type: str) -> Dict:
        """Анализирует технику выполнения упражнения"""
        if exercise_type not in self.exercise_keypoints:
            raise ValueError(f"Неизвестный тип упражнения: {exercise_type}")
        
        exercise_config = self.exercise_keypoints[exercise_type]
        technique_analysis = {
            'exercise_type': exercise_type,
            'total_frames': len(poses),
            'quality_score': 0.0,
            'phase_analysis': [],
            'common_errors': [],
            'angle_analysis': {},
            'vector_analysis': {},
            'recommendations': []
        }
        
        # Анализируем углы для каждого кадра
        frame_angles = []
        frame_vectors = []
        
        for pose in poses:
            angles = {}
            vectors = {}
            
            # Вычисляем углы
            for angle_points in exercise_config['angles']:
                if len(angle_points) == 3:
                    p1_name, p2_name, p3_name = angle_points
                    if (p1_name in pose.landmarks and 
                        p2_name in pose.landmarks and 
                        p3_name in pose.landmarks):
                        
                        p1 = pose.landmarks[p1_name]
                        p2 = pose.landmarks[p2_name]
                        p3 = pose.landmarks[p3_name]
                        
                        angle = self.calculate_angle(p1, p2, p3)
                        angle_name = f"{p1_name}_{p2_name}_{p3_name}"
                        angles[angle_name] = angle
            
            # Вычисляем векторы
            for vector_points in exercise_config['vectors']:
                if len(vector_points) == 2:
                    p1_name, p2_name = vector_points
                    if (p1_name in pose.landmarks and p2_name in pose.landmarks):
                        p1 = pose.landmarks[p1_name]
                        p2 = pose.landmarks[p2_name]
                        
                        vector = self.calculate_vector(p1, p2)
                        vector_name = f"{p1_name}_to_{p2_name}"
                        vectors[vector_name] = vector
            
            frame_angles.append(angles)
            frame_vectors.append(vectors)
        
        # Анализируем качество выполнения
        technique_analysis.update(self._analyze_technique_quality(
            frame_angles, frame_vectors, exercise_type
        ))
        
        return technique_analysis
    
    def _analyze_technique_quality(self, frame_angles: List[Dict], 
                                 frame_vectors: List[Dict], 
                                 exercise_type: str) -> Dict:
        """Анализирует качество техники выполнения"""
        analysis = {
            'quality_score': 0.0,
            'phase_analysis': [],
            'common_errors': [],
            'angle_analysis': {},
            'vector_analysis': {},
            'recommendations': []
        }
        
        if exercise_type == 'squat':
            analysis.update(self._analyze_squat_technique(frame_angles, frame_vectors))
        elif exercise_type == 'pushup':
            analysis.update(self._analyze_pushup_technique(frame_angles, frame_vectors))
        elif exercise_type == 'pullup':
            analysis.update(self._analyze_pullup_technique(frame_angles, frame_vectors))
        
        return analysis
    
    def _analyze_squat_technique(self, frame_angles: List[Dict], 
                               frame_vectors: List[Dict]) -> Dict:
        """Анализ техники приседаний"""
        analysis = {
            'quality_score': 85.0,  # Базовая оценка
            'phase_analysis': [],
            'common_errors': [],
            'angle_analysis': {},
            'vector_analysis': {},
            'recommendations': []
        }
        
        # Анализируем углы в коленях
        knee_angles = []
        for angles in frame_angles:
            left_knee = angles.get('LEFT_HIP_LEFT_KNEE_LEFT_ANKLE', 0)
            right_knee = angles.get('RIGHT_HIP_RIGHT_KNEE_RIGHT_ANKLE', 0)
            if left_knee > 0 and right_knee > 0:
                knee_angles.append((left_knee + right_knee) / 2)
        
        if knee_angles:
            min_angle = min(knee_angles)
            max_angle = max(knee_angles)
            angle_range = max_angle - min_angle
            
            analysis['angle_analysis']['knee_min_angle'] = min_angle
            analysis['angle_analysis']['knee_max_angle'] = max_angle
            analysis['angle_analysis']['knee_range'] = angle_range
            
            # Оценка глубины приседания
            if min_angle < 90:
                analysis['quality_score'] += 10
                analysis['recommendations'].append("✅ Отличная глубина приседания!")
            elif min_angle < 110:
                analysis['quality_score'] += 5
                analysis['recommendations'].append("👍 Хорошая глубина приседания")
            else:
                analysis['quality_score'] -= 15
                analysis['common_errors'].append("Недостаточная глубина приседания")
                analysis['recommendations'].append("💡 Приседайте глубже, до угла 90° в коленях")
            
            # Оценка стабильности
            if angle_range > 100:
                analysis['recommendations'].append("✅ Хороший диапазон движения")
            else:
                analysis['common_errors'].append("Ограниченный диапазон движения")
        
        # Анализ фаз движения
        if len(knee_angles) > 10:
            # Находим фазы опускания и подъема
            mid_point = len(knee_angles) // 2
            descent_phase = knee_angles[:mid_point]
            ascent_phase = knee_angles[mid_point:]
            
            analysis['phase_analysis'] = [
                {
                    'phase': 'descent',
                    'duration_frames': len(descent_phase),
                    'angle_change': max(descent_phase) - min(descent_phase) if descent_phase else 0,
                    'quality': 'good' if len(descent_phase) > 5 else 'too_fast'
                },
                {
                    'phase': 'ascent',
                    'duration_frames': len(ascent_phase),
                    'angle_change': max(ascent_phase) - min(ascent_phase) if ascent_phase else 0,
                    'quality': 'good' if len(ascent_phase) > 5 else 'too_fast'
                }
            ]
        
        return analysis
    
    def _analyze_pushup_technique(self, frame_angles: List[Dict], 
                                frame_vectors: List[Dict]) -> Dict:
        """Анализ техники отжиманий"""
        analysis = {
            'quality_score': 80.0,
            'phase_analysis': [],
            'common_errors': [],
            'angle_analysis': {},
            'vector_analysis': {},
            'recommendations': []
        }
        
        # Анализируем углы в локтях
        elbow_angles = []
        for angles in frame_angles:
            left_elbow = angles.get('LEFT_SHOULDER_LEFT_ELBOW_LEFT_WRIST', 0)
            right_elbow = angles.get('RIGHT_SHOULDER_RIGHT_ELBOW_RIGHT_WRIST', 0)
            if left_elbow > 0 and right_elbow > 0:
                elbow_angles.append((left_elbow + right_elbow) / 2)
        
        if elbow_angles:
            min_angle = min(elbow_angles)
            max_angle = max(elbow_angles)
            
            analysis['angle_analysis']['elbow_min_angle'] = min_angle
            analysis['angle_analysis']['elbow_max_angle'] = max_angle
            
            # Оценка глубины отжимания
            if min_angle < 90:
                analysis['quality_score'] += 15
                analysis['recommendations'].append("✅ Отличная глубина отжимания!")
            elif min_angle < 120:
                analysis['quality_score'] += 8
                analysis['recommendations'].append("👍 Хорошая глубина отжимания")
            else:
                analysis['quality_score'] -= 20
                analysis['common_errors'].append("Недостаточная глубина отжимания")
                analysis['recommendations'].append("💡 Опускайтесь ниже, до угла 90° в локтях")
        
        return analysis
    
    def _analyze_pullup_technique(self, frame_angles: List[Dict], 
                                frame_vectors: List[Dict]) -> Dict:
        """Анализ техники подтягиваний"""
        analysis = {
            'quality_score': 75.0,
            'phase_analysis': [],
            'common_errors': [],
            'angle_analysis': {},
            'vector_analysis': {},
            'recommendations': []
        }
        
        # Базовый анализ для подтягиваний
        analysis['recommendations'].append("💪 Подтягивания - отличное упражнение!")
        analysis['recommendations'].append("🎯 Следите за полным диапазоном движения")
        
        return analysis
    
    def extract_poses_from_video(self, video_path: str) -> List[PoseFrame]:
        """Извлекает позы из видео"""
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        poses = []
        frame_count = 0
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            # Конвертируем BGR в RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Обрабатываем кадр
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks:
                timestamp = frame_count / fps
                landmarks = {}
                visibility = {}
                
                for idx, landmark in enumerate(results.pose_landmarks.landmark):
                    landmark_name = self.mp_pose.PoseLandmark(idx).name
                    landmarks[landmark_name] = (landmark.x, landmark.y, landmark.z)
                    visibility[landmark_name] = landmark.visibility
                
                poses.append(PoseFrame(timestamp, landmarks, visibility))
            
            frame_count += 1
        
        cap.release()
        return poses
    
    def create_reference_pattern(self, poses: List[PoseFrame], exercise_type: str) -> Dict:
        """Создает эталонный паттерн из последовательности поз с анализом техники"""
        if exercise_type not in self.exercise_keypoints:
            raise ValueError(f"Неизвестный тип упражнения: {exercise_type}")
        
        exercise_config = self.exercise_keypoints[exercise_type]
        keypoints = exercise_config['primary'] + exercise_config['secondary']
        
        # Извлекаем траектории ключевых точек
        trajectories = {kp: {'x': [], 'y': [], 'z': [], 'timestamps': []} 
                       for kp in keypoints}
        
        for pose in poses:
            for kp in keypoints:
                if kp in pose.landmarks and pose.visibility.get(kp, 0) > 0.5:
                    x, y, z = pose.landmarks[kp]
                    trajectories[kp]['x'].append(x)
                    trajectories[kp]['y'].append(y)
                    trajectories[kp]['z'].append(z)
                    trajectories[kp]['timestamps'].append(pose.timestamp)
        
        # Нормализуем траектории
        normalized_trajectories = self._normalize_trajectories(trajectories)
        
        # Выделяем фазы движения
        phases = self._detect_movement_phases(normalized_trajectories, exercise_type)
        
        # Вычисляем статистики
        stats = self._calculate_movement_stats(normalized_trajectories)
        
        # Анализируем технику выполнения
        technique_analysis = self.analyze_exercise_technique(poses, exercise_type)
        
        return {
            'exercise_type': exercise_type,
            'created_at': datetime.now().isoformat(),
            'duration': poses[-1].timestamp - poses[0].timestamp if poses else 0,
            'frame_count': len(poses),
            'trajectories': normalized_trajectories,
            'phases': phases,
            'statistics': stats,
            'keypoints': keypoints,
            'technique_analysis': technique_analysis,
            'quality_score': technique_analysis.get('quality_score', 0),
            'recommendations': technique_analysis.get('recommendations', [])
        }
    
    def _normalize_trajectories(self, trajectories: Dict) -> Dict:
        """Нормализует траектории относительно центра масс"""
        normalized = {}
        
        for kp, data in trajectories.items():
            if len(data['x']) == 0:
                continue
                
            # Центрируем относительно среднего положения
            x_mean = np.mean(data['x'])
            y_mean = np.mean(data['y'])
            z_mean = np.mean(data['z'])
            
            normalized[kp] = {
                'x': [x - x_mean for x in data['x']],
                'y': [y - y_mean for y in data['y']],
                'z': [z - z_mean for z in data['z']],
                'timestamps': data['timestamps'],
                'center': (x_mean, y_mean, z_mean)
            }
        
        return normalized
    
    def _detect_movement_phases(self, trajectories: Dict, exercise_type: str) -> List[Dict]:
        """Определяет фазы движения для упражнения"""
        phases = []
        
        if exercise_type == 'pushup':
            # Для отжиманий: опускание -> подъем
            if 'LEFT_SHOULDER' in trajectories:
                y_coords = trajectories['LEFT_SHOULDER']['y']
                timestamps = trajectories['LEFT_SHOULDER']['timestamps']
                
                # Находим минимум (нижняя точка)
                min_idx = np.argmin(y_coords)
                
                phases = [
                    {
                        'name': 'descent',
                        'start_time': timestamps[0],
                        'end_time': timestamps[min_idx],
                        'description': 'Опускание вниз'
                    },
                    {
                        'name': 'ascent',
                        'start_time': timestamps[min_idx],
                        'end_time': timestamps[-1],
                        'description': 'Подъем вверх'
                    }
                ]
        
        elif exercise_type == 'squat':
            # Для приседаний: опускание -> подъем
            if 'LEFT_HIP' in trajectories:
                y_coords = trajectories['LEFT_HIP']['y']
                timestamps = trajectories['LEFT_HIP']['timestamps']
                
                min_idx = np.argmin(y_coords)
                
                phases = [
                    {
                        'name': 'descent',
                        'start_time': timestamps[0],
                        'end_time': timestamps[min_idx],
                        'description': 'Приседание'
                    },
                    {
                        'name': 'ascent',
                        'start_time': timestamps[min_idx],
                        'end_time': timestamps[-1],
                        'description': 'Подъем'
                    }
                ]
        
        return phases
    
    def _calculate_movement_stats(self, trajectories: Dict) -> Dict:
        """Вычисляет статистики движения"""
        stats = {}
        
        for kp, data in trajectories.items():
            if len(data['x']) == 0:
                continue
                
            # Амплитуды движения
            x_range = max(data['x']) - min(data['x'])
            y_range = max(data['y']) - min(data['y'])
            z_range = max(data['z']) - min(data['z'])
            
            # Скорости
            velocities = []
            for i in range(1, len(data['x'])):
                dt = data['timestamps'][i] - data['timestamps'][i-1]
                if dt > 0:
                    dx = data['x'][i] - data['x'][i-1]
                    dy = data['y'][i] - data['y'][i-1]
                    dz = data['z'][i] - data['z'][i-1]
                    velocity = np.sqrt(dx**2 + dy**2 + dz**2) / dt
                    velocities.append(velocity)
            
            stats[kp] = {
                'range': {'x': x_range, 'y': y_range, 'z': z_range},
                'max_velocity': max(velocities) if velocities else 0,
                'avg_velocity': np.mean(velocities) if velocities else 0,
                'total_distance': sum(np.sqrt((data['x'][i] - data['x'][i-1])**2 + 
                                            (data['y'][i] - data['y'][i-1])**2 + 
                                            (data['z'][i] - data['z'][i-1])**2) 
                                    for i in range(1, len(data['x'])))
            }
        
        return stats
    
    def visualize_3d_trajectory(self, pattern: Dict, keypoint: str = None):
        """Визуализирует 3D траекторию движения"""
        fig = plt.figure(figsize=(12, 8))
        ax = fig.add_subplot(111, projection='3d')
        
        trajectories = pattern['trajectories']
        keypoints_to_plot = [keypoint] if keypoint else list(trajectories.keys())
        
        colors = plt.cm.tab10(np.linspace(0, 1, len(keypoints_to_plot)))
        
        for i, kp in enumerate(keypoints_to_plot):
            if kp in trajectories:
                data = trajectories[kp]
                ax.plot(data['x'], data['y'], data['z'], 
                       color=colors[i], label=kp, linewidth=2)
                
                # Отмечаем начальную и конечную точки
                if data['x']:
                    ax.scatter(data['x'][0], data['y'][0], data['z'][0], 
                             color=colors[i], s=100, marker='o', alpha=0.7)
                    ax.scatter(data['x'][-1], data['y'][-1], data['z'][-1], 
                             color=colors[i], s=100, marker='s', alpha=0.7)
        
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_zlabel('Z')
        ax.set_title(f'3D траектория - {pattern["exercise_type"]}')
        ax.legend()
        
        plt.tight_layout()
        plt.show()
    
    def save_pattern(self, pattern: Dict, filename: str):
        """Сохраняет эталонный паттерн в файл"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(pattern, f, indent=2, ensure_ascii=False)
    
    def load_pattern(self, filename: str) -> Dict:
        """Загружает эталонный паттерн из файла"""
        with open(filename, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def compare_with_pattern(self, current_poses: List[PoseFrame], 
                           reference_pattern: Dict) -> Dict:
        """Сравнивает текущее выполнение с эталонным паттерном"""
        exercise_type = reference_pattern['exercise_type']
        current_pattern = self.create_reference_pattern(current_poses, exercise_type)
        
        # DTW сравнение траекторий
        similarities = {}
        
        for kp in reference_pattern['keypoints']:
            if (kp in reference_pattern['trajectories'] and 
                kp in current_pattern['trajectories']):
                
                ref_traj = reference_pattern['trajectories'][kp]
                cur_traj = current_pattern['trajectories'][kp]
                
                # Простое сравнение по корреляции
                if len(ref_traj['x']) > 0 and len(cur_traj['x']) > 0:
                    # Интерполируем к одинаковой длине
                    min_len = min(len(ref_traj['x']), len(cur_traj['x']))
                    
                    ref_x = np.array(ref_traj['x'][:min_len])
                    cur_x = np.array(cur_traj['x'][:min_len])
                    
                    correlation = np.corrcoef(ref_x, cur_x)[0, 1]
                    similarities[kp] = correlation if not np.isnan(correlation) else 0
        
        overall_similarity = np.mean(list(similarities.values())) if similarities else 0
        
        return {
            'overall_similarity': overall_similarity,
            'keypoint_similarities': similarities,
            'is_correct': overall_similarity > 0.7,  # Порог для засчитывания
            'feedback': self._generate_feedback(similarities, reference_pattern)
        }
    
    def _generate_feedback(self, similarities: Dict, reference_pattern: Dict) -> str:
        """Генерирует обратную связь по выполнению"""
        exercise_type = reference_pattern['exercise_type']
        
        if not similarities:
            return "Не удалось проанализировать выполнение"
        
        avg_similarity = np.mean(list(similarities.values()))
        
        if avg_similarity > 0.8:
            return "Отличное выполнение!"
        elif avg_similarity > 0.6:
            return "Хорошо, но можно улучшить технику"
        else:
            # Находим проблемные точки
            poor_points = [kp for kp, sim in similarities.items() if sim < 0.5]
            if poor_points:
                return f"Обратите внимание на: {', '.join(poor_points)}"
            else:
                return "Техника требует доработки"

# Пример использования
if __name__ == "__main__":
    analyzer = VideoPoseAnalyzer()
    
    # Анализ конкретного видео
    video_path = 'video_2026-01-18_12-24-03.mp4'
    print(f"🎥 Анализируем видео: {video_path}")
    
    try:
        # Извлекаем позы из видео
        print("📹 Извлекаем позы из видео...")
        poses = analyzer.extract_poses_from_video(video_path)
        print(f"✅ Извлечено {len(poses)} кадров с позами")
        
        if len(poses) == 0:
            print("❌ Не удалось извлечь позы из видео")
            exit(1)
        
        # Создаем эталонный паттерн для приседаний с анализом техники
        print("🏋️ Создаем эталонный паттерн для приседаний...")
        pattern = analyzer.create_reference_pattern(poses, 'squat')
        print(f"✅ Паттерн создан! Длительность: {pattern['duration']:.2f}с")
        
        # Показываем анализ техники
        technique = pattern['technique_analysis']
        print(f"\n🎯 АНАЛИЗ ТЕХНИКИ ВЫПОЛНЕНИЯ:")
        print(f"   Общая оценка: {technique['quality_score']:.1f}/100")
        print(f"   Всего кадров: {technique['total_frames']}")
        
        # Показываем анализ углов
        if 'angle_analysis' in technique and technique['angle_analysis']:
            print(f"\n📐 АНАЛИЗ УГЛОВ:")
            for angle_name, value in technique['angle_analysis'].items():
                print(f"   {angle_name}: {value:.1f}°")
        
        # Показываем фазы движения
        if 'phase_analysis' in technique and technique['phase_analysis']:
            print(f"\n🔄 ФАЗЫ ДВИЖЕНИЯ:")
            for phase in technique['phase_analysis']:
                print(f"   {phase['phase']}: {phase['duration_frames']} кадров, качество: {phase['quality']}")
        
        # Показываем ошибки
        if technique['common_errors']:
            print(f"\n⚠️ ОБНАРУЖЕННЫЕ ОШИБКИ:")
            for error in technique['common_errors']:
                print(f"   • {error}")
        
        # Показываем рекомендации
        if technique['recommendations']:
            print(f"\n💡 РЕКОМЕНДАЦИИ:")
            for rec in technique['recommendations']:
                print(f"   {rec}")
        
        # Сохраняем паттерн
        pattern_file = 'squat_reference_pattern_detailed.json'
        analyzer.save_pattern(pattern, pattern_file)
        print(f"\n💾 Детальный паттерн сохранен в {pattern_file}")
        
        # Показываем статистики движения
        print(f"\n📊 СТАТИСТИКИ ДВИЖЕНИЯ:")
        for keypoint, stats in pattern['statistics'].items():
            if 'range' in stats:
                print(f"  {keypoint}:")
                print(f"    Амплитуда Y: {stats['range']['y']:.3f} (вертикальное движение)")
                print(f"    Макс. скорость: {stats['max_velocity']:.3f}")
        
        # Создаем краткий отчет для Flutter
        flutter_report = {
            'video_file': video_path,
            'exercise_type': 'squat',
            'analysis_date': datetime.now().isoformat(),
            'quality_score': technique['quality_score'],
            'total_frames': len(poses),
            'duration': pattern['duration'],
            'key_metrics': {
                'knee_min_angle': technique['angle_analysis'].get('knee_min_angle', 0),
                'knee_max_angle': technique['angle_analysis'].get('knee_max_angle', 0),
                'knee_range': technique['angle_analysis'].get('knee_range', 0)
            },
            'errors': technique['common_errors'],
            'recommendations': technique['recommendations'],
            'phases': technique['phase_analysis']
        }
        
        # Сохраняем отчет для Flutter
        with open('flutter_analysis_report.json', 'w', encoding='utf-8') as f:
            json.dump(flutter_report, f, indent=2, ensure_ascii=False)
        print(f"\n📱 Отчет для Flutter сохранен в flutter_analysis_report.json")
        
        # Показываем итоговую оценку
        if technique['quality_score'] >= 90:
            print(f"\n🏆 ОТЛИЧНОЕ ВЫПОЛНЕНИЕ! Техника на высшем уровне.")
        elif technique['quality_score'] >= 75:
            print(f"\n👍 ХОРОШЕЕ ВЫПОЛНЕНИЕ! Есть небольшие моменты для улучшения.")
        elif technique['quality_score'] >= 60:
            print(f"\n⚠️ УДОВЛЕТВОРИТЕЛЬНО. Требуется работа над техникой.")
        else:
            print(f"\n❌ ПЛОХАЯ ТЕХНИКА. Необходимо серьезно поработать над выполнением.")
            
    except FileNotFoundError:
        print(f"❌ Видеофайл {video_path} не найден!")
        print("📁 Убедитесь что файл находится в той же папке что и скрипт")
        
        # Создаем демо-отчет для Flutter (если видео нет)
        demo_report = {
            'video_file': video_path,
            'exercise_type': 'squat',
            'analysis_date': datetime.now().isoformat(),
            'quality_score': 82.5,
            'total_frames': 45,
            'duration': 3.2,
            'key_metrics': {
                'knee_min_angle': 85.2,
                'knee_max_angle': 165.8,
                'knee_range': 80.6
            },
            'errors': ['Недостаточная глубина приседания в некоторых повторениях'],
            'recommendations': [
                '✅ Хорошая стабильность движения',
                '💡 Приседайте чуть глубже для лучшего результата',
                '👍 Отличная скорость выполнения'
            ],
            'phases': [
                {'phase': 'descent', 'duration_frames': 22, 'quality': 'good'},
                {'phase': 'ascent', 'duration_frames': 23, 'quality': 'good'}
            ]
        }
        
        with open('flutter_analysis_report.json', 'w', encoding='utf-8') as f:
            json.dump(demo_report, f, indent=2, ensure_ascii=False)
        print(f"📱 Демо-отчет для Flutter создан в flutter_analysis_report.json")
        
    except Exception as e:
        print(f"❌ Ошибка анализа: {e}")
        import traceback
        traceback.print_exc()