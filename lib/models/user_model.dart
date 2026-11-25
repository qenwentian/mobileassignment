import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  normal('normal', 'Normal User'),
  admin('admin', 'Admin');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String? firestoreRole) =>
      firestoreRole == 'admin' ? UserRole.admin : UserRole.normal;
}

class UserModel {
  final String id;
  final String studentId;
  final String name;
  final String email;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    this.role = UserRole.normal,
  });

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromMap(String id, Map<String, dynamic> data) => UserModel(
        id: id,
        studentId: (data['studentId'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        role: UserRole.fromValue(data['role'] as String?),
      );

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      UserModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'name': name,
        'email': email,
        'role': role.value,
      };

  UserModel copyWith({
    String? studentId,
    String? name,
    String? email,
    UserRole? role,
  }) =>
      UserModel(
        id: id,
        studentId: studentId ?? this.studentId,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
      );
}
