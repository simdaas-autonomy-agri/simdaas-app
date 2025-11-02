import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'] as String, email: json['email'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
