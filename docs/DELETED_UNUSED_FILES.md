# Список удалённых неиспользуемых файлов

Дата анализа: 30.01.2025

## Результат глубокого анализа проекта

Проведён полный анализ графа импортов и навигации в `lib/`. Удалены файлы, которые **нигде не импортируются** и не участвуют в навигации приложения.

---

## Удалённые файлы (27 шт.)

### Корень lib/
| № | Путь |
|---|------|
| 1 | `lib/main_simple.dart` — альтернативная точка входа, нигде не используется |

### Core
| № | Путь |
|---|------|
| 2 | `lib/core/services/dio_client.dart` — использовался только удалённым `remote_food_datasource` |
| 3 | `lib/core/services/storage_service.dart` — нигде не импортируется |
| 4 | `lib/core/services/profile_service.dart` — нигде не импортируется |
| 5 | `lib/core/widgets/loading_overlay.dart` — нигде не импортируется |

### Diet (питание)
| № | Путь |
|---|------|
| 6 | `lib/features/diet/data/datasources/remote_food_datasource.dart` — репозиторий использует только `LocalFoodDatasource` |
| 7 | `lib/features/diet/data/food_database.dart` — дублирует логику; используется `FoodDatabaseService` |

### Auth
| № | Путь |
|---|------|
| 8 | `lib/features/auth/presentation/pages/login_page.dart` — экран входа никуда не открывается (навигация отсутствует) |

### Exercises — сервисы
| № | Путь |
|---|------|
| 9 | `lib/features/exercises/services/pose_detection_service.dart` — использовался только удалённым `rep_counter_service` |
| 10 | `lib/features/exercises/services/optimized_pose_detection_service.dart` — использовался только `pose_detection_service` |
| 11 | `lib/features/exercises/services/rep_counter_service.dart` — нигде не импортируется (в приложении используется `ImprovedRepCounter`) |
| 12 | `lib/features/exercises/services/simple_rep_counter.dart` — нигде не импортируется |
| 13 | `lib/features/exercises/services/optimized_pose_analyzer.dart` — нигде не импортируется |

### Exercises — доменные модели
| № | Путь |
|---|------|
| 14 | `lib/features/exercises/domain/models/adaptive_workout.dart` — нигде не импортируется |

### Exercises — страницы (тестовые/неиспользуемые)
| № | Путь |
|---|------|
| 15 | `lib/features/exercises/presentation/pages/simple_camera_test_page.dart` |
| 16 | `lib/features/exercises/presentation/pages/simple_pose_test_page.dart` |
| 17 | `lib/features/exercises/presentation/pages/demo_camera_page.dart` |
| 18 | `lib/features/exercises/presentation/pages/mock_camera_page.dart` |
| 19 | `lib/features/exercises/presentation/pages/optimized_camera_page.dart` |
| 20 | `lib/features/exercises/presentation/pages/muscle_group_test_page.dart` |
| 21 | `lib/features/exercises/presentation/pages/pose_test_page.dart` |
| 22 | `lib/features/exercises/presentation/pages/video_analysis_page.dart` |
| 23 | `lib/features/exercises/presentation/pages/workout_history_page.dart` |
| 24 | `lib/features/exercises/presentation/pages/workout_page.dart` |

### Exercises — виджеты
| № | Путь |
|---|------|
| 25 | `lib/features/exercises/presentation/widgets/key_points_info_widget.dart` — использовался только удалённой `optimized_camera_page` |
| 26 | `lib/features/exercises/presentation/widgets/muscle_diagram.dart` — нигде не импортируется |
| 27 | `lib/features/exercises/presentation/widgets/rep_phase_indicator.dart` — нигде не импортируется |

---

## Фича Profile (заглушки добавлены)

**До удалений** в проекте были ссылки на несуществующую фичу `profile`. Чтобы проект собирался, добавлены минимальные заглушки:

- `lib/features/profile/presentation/pages/profile_page.dart` — страница-заглушка «Раздел в разработке»
- `lib/features/profile/services/experience_service.dart` — `addExperience(int)` возвращает переданное значение
- `lib/features/profile/presentation/widgets/experience_notification.dart` — показывает SnackBar «+N опыт»

В дальнейшем их можно заменить полноценной реализацией (сохранение опыта в Hive, экран прогресса и т.д.).

---

## Не удалялось

- **Тесты** — оставлены; часть из них ссылается на удалённый код (например, `security_utils_test` на `security_utils` — `security_utils` оставлен, т.к. используется в тестах).
- **Сгенерированные файлы** (`*.g.dart`) — не трогались.
- **Файлы в `assets/`, `android/`, `ios/`, `web/`, `windows/`** — не анализировались на предмет использования; при необходимости их можно проверить отдельно.
