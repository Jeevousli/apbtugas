import 'package:equatable/equatable.dart';

enum UserRole { employee, admin }

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String nik;
  final UserRole role;
  final DateTime createdAt;
  final String? fcmToken;
  final String? photoUrl;
  final String? phone;
  final String? department;
  final String? position;
  final String? employeeStatus;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.nik,
    required this.role,
    required this.createdAt,
    this.fcmToken,
    this.photoUrl,
    this.phone,
    this.department,
    this.position,
    this.employeeStatus,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        nik,
        role,
        createdAt,
        fcmToken,
        photoUrl,
        phone,
        department,
        position,
        employeeStatus,
      ];
}
