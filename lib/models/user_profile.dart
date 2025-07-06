import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  String userName;
  int age;
  String gender;
  double height;
  double weight;
  String email;
  String password;

  UserData({
    this.userName = '',
    this.age = 0,
    this.gender = '',
    this.height = 0.0,
    this.weight = 0.0,
    this.email = '',
    this.password = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Needs the import
    };
  }
}
