import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.nik,
    required super.role,
    required super.createdAt,
    super.fcmToken,
    super.photoUrl,
    super.phone,
    super.department,
    super.position,
    super.employeeStatus,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nik: data['nik'] ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.employee,
      createdAt: parsedDate,
      fcmToken: data['fcmToken'],
      photoUrl: data['photoUrl'],
      phone: data['phone'],
      department: data['department'],
      position: data['position'],
      employeeStatus: data['employeeStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'nik': nik,
      'role': role == UserRole.admin ? 'admin' : 'employee',
      'createdAt': Timestamp.fromDate(createdAt),
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (position != null) 'position': position,
      if (employeeStatus != null) 'employeeStatus': employeeStatus,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      nik: entity.nik,
      role: entity.role,
      createdAt: entity.createdAt,
      fcmToken: entity.fcmToken,
      photoUrl: entity.photoUrl,
      phone: entity.phone,
      department: entity.department,
      position: entity.position,
      employeeStatus: entity.employeeStatus,
    );
  }
}
