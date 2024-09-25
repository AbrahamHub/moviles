import 'package:sqflite/sqflite.dart';
import 'package:tutorial/database/database_service.dart';
import 'package:tutorial/models/user.dart';

class UserDB {
  final tableName = 'user';

  Future<void> createTable(Database database) async {
    await database.execute("""CREATE TABLE IF NOT EXISTS $tableName (
      "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      "username" TEXT NOT NULL,
      "email" TEXT NOT NULL,
      "password" TEXT NOT NULL,
      "created_at" INTEGER NOT NULL DEFAULT (cast(strftime('%s', 'now') AS INTEGER)),
      "updated_at" INTEGER
    );""");  // Corregido: se quitó la coma antes del paréntesis de cierre
  }

  Future<int> create({required String username, required String email, required String password}) async {
    final dbService = DatabaseService();
    final db = await dbService.database;

    final user = {
      'username': username,
      'email': email,
      'password': password,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': null,  // Corregido: la clave era 'updated:at' en vez de 'updated_at'
    };

    return await db.insert(tableName, user);
  }

  Future<List<User>> fetchAll() async {
    final database = await DatabaseService().database;
    final List<Map<String, dynamic>> users = await database.rawQuery(
        '''SELECT * FROM $tableName ORDER BY COALESCE(updated_at, created_at) DESC'''
    );

    return users.map((userMap) => User(
      username: userMap['username'],
      email: userMap['email'],
      password: userMap['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(userMap['created_at']),
      updatedAt: userMap['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(userMap['updated_at']) : null,
    )).toList();
  }

  Future<User?> fetchByUsername(String username) async {
    final database = await DatabaseService().database;
    final List<Map<String, dynamic>> userMaps = await database.query(
      tableName,
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userMaps.isNotEmpty) {
      final userMap = userMaps.first;
      return User(
        username: userMap['username'],
        email: userMap['email'],
        password: userMap['password'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(userMap['created_at']),
        updatedAt: userMap['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(userMap['updated_at']) : null,
      );
    }
    return null; // Return null if no user is found
  }
}


