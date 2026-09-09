/// Maps to PostgreSQL ENUM `user_role` ('ADMIN', 'MANAGER', 'STAFF').
enum UserRole {
  admin('ADMIN'),
  manager('MANAGER'),
  staff('STAFF');

  const UserRole(this.dbValue);

  /// The value stored in PostgreSQL.
  final String dbValue;

  /// Parses a database string into a [UserRole].
  ///
  /// Throws [ArgumentError] if the value is not recognized.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.dbValue == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unknown UserRole: $value'),
    );
  }

  /// Whether this role has at least manager-level access.
  bool get isManagerOrAbove => this == UserRole.admin || this == UserRole.manager;

  /// Whether this role has admin-level access.
  bool get isAdmin => this == UserRole.admin;
}
