import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? avatar;

  @HiveField(3)
  bool isOnline;

  @HiveField(4)
  DateTime lastSeen;

  @HiveField(5)
  String? ipAddress;

  User({required this.id, required this.name, this.avatar, this.isOnline = false, required this.lastSeen, this.ipAddress});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
      ipAddress: json['ipAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatar': avatar, 'isOnline': isOnline, 'lastSeen': lastSeen.toIso8601String(), 'ipAddress': ipAddress};
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, isOnline: $isOnline, ip: $ipAddress)';
  }
}
