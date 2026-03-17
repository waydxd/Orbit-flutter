import 'base_model.dart';

/// User model representing authenticated user data
class UserModel extends BaseModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? profilePicture;
  final String? region;
  final String? timezone;
  final String? gender;
  final DateTime? birthDate;
  final bool? emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.profilePicture,
    this.region,
    this.timezone,
    this.gender,
    this.birthDate,
    this.emailVerified,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.trim().isNotEmpty)
      return username!.trim();
    return email;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? profilePicture,
    String? region,
    String? timezone,
    String? gender,
    DateTime? birthDate,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      region: region ?? this.region,
      timezone: timezone ?? this.timezone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (username != null) 'username': username,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (region != null) 'region': region,
      if (timezone != null) 'timezone': timezone,
      if (gender != null) 'gender': gender,
      if (birthDate != null)
        'birth_date':
            '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
      if (emailVerified != null) 'email_verified': emailVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is! String || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      profilePicture: json['profile_picture'] as String?,
      region: json['region'] as String?,
      timezone: json['timezone'] as String?,
      gender: json['gender'] as String?,
      birthDate: parseDate(json['birth_date']),
      emailVerified: json['email_verified'] as bool?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        username,
        profilePicture,
        region,
        timezone,
        gender,
        birthDate,
        emailVerified,
        createdAt,
        updatedAt,
      ];
}
