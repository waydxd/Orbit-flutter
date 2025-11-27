import 'base_model.dart';

/// User model representing authenticated user data
class UserModel extends BaseModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName];
}
