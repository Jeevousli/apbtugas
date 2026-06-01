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
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nik: data['nik'] ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.employee,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
      photoUrl: data['photoUrl'],
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
    );
  }
}
