import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String username;

  @HiveField(3)
  String? firstName;

  @HiveField(4)
  String? lastName;

  @HiveField(5)
  DateTime? dateOfBirth;

  @HiveField(6)
  String? gender;

  @HiveField(7)
  double? height; // в см

  @HiveField(8)
  double? weight; // в кг

  @HiveField(9)
  String? fitnessLevel; // beginner, intermediate, advanced

  @HiveField(10)
  List<String>? fitnessGoals; // weight_loss, muscle_gain, endurance, etc.

  @HiveField(11)
  String? profileImagePath;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  bool isActive;

  @HiveField(15)
  Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.fitnessLevel,
    this.fitnessGoals,
    this.profileImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.preferences,
  });

  // Геттеры для вычисляемых полей
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Неизвестно';
    
    if (bmiValue < 18.5) return 'Недостаточный вес';
    if (bmiValue < 25) return 'Нормальный вес';
    if (bmiValue < 30) return 'Избыточный вес';
    return 'Ожирение';
  }

  // Методы для работы с данными
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? fitnessLevel,
    List<String>? fitnessGoals,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fitnessLevel: json['fitnessLevel'],
      fitnessGoals: json['fitnessGoals']?.cast<String>(),
      profileImagePath: json['profileImagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      preferences: json['preferences']?.cast<String, dynamic>(),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, username: $username, fullName: $fullName)';
  }
}