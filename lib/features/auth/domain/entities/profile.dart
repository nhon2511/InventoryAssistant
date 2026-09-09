import 'package:smart_wms/core/enums/user_role.dart';

/// Pure domain entity representing a user profile.
///
/// Maps to the `profiles` table in Supabase (linked to `auth.users`).
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  /// UUID primary key (same as `auth.users.id`).
  final String id;

  /// Full name of the user.
  final String fullName;

  /// Role-based access control level.
  final UserRole role;

  /// Optional phone number.
  final String? phoneNumber;

  /// Account creation timestamp.
  final DateTime? createdAt;
}
