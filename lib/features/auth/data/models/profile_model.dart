import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';

/// Data transfer object for the `profiles` table.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'STAFF',
      phoneNumber: json['phone_number'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'phone_number': phoneNumber,
      'created_at': createdAt,
    };
  }

  Profile toEntity() {
    return Profile(
      id: id,
      fullName: fullName,
      role: UserRole.fromString(role),
      phoneNumber: phoneNumber,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
    );
  }

  factory ProfileModel.fromEntity(Profile entity) {
    return ProfileModel(
      id: entity.id,
      fullName: entity.fullName,
      role: entity.role.dbValue,
      phoneNumber: entity.phoneNumber,
      createdAt: entity.createdAt?.toIso8601String(),
    );
  }
}

