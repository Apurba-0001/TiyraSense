enum UserRole {
  driver,
  fieldWorker,
  official,
  admin;

  static UserRole fromString(String val) {
    switch (val.toUpperCase()) {
      case 'DRIVER':
        return UserRole.driver;
      case 'FIELD_WORKER':
        return UserRole.fieldWorker;
      case 'OFFICIAL':
        return UserRole.official;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.driver;
    }
  }

  String toDisplayString() {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.fieldWorker:
        return 'Field Worker';
      case UserRole.official:
        return 'Official';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String toApiRole() {
    switch (this) {
      case UserRole.driver:
        return 'DRIVER';
      case UserRole.fieldWorker:
        return 'FIELD_WORKER';
      case UserRole.official:
        return 'OFFICIAL';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phoneNumber;
  final String? organization;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.organization,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'DRIVER'),
      phoneNumber: json['phone_number'] as String?,
      organization: json['organization'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toApiRole(),
      'phone_number': phoneNumber,
      'organization': organization,
    };
  }
}
