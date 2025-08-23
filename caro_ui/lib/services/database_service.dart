// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // --- Singleton Pattern ---
  // Điều này đảm bảo rằng chúng ta chỉ có MỘT thực thể (instance) của DatabaseService
  // trong toàn bộ ứng dụng, giúp quản lý kết nối database một cách nhất quán.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // --- Getter để lấy database ---
  // Lần đầu gọi, nó sẽ khởi tạo database. Những lần sau sẽ trả về
  // database đã được mở sẵn.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // --- Khởi tạo Database ---
  Future<Database> _initDB() async {
    // Lấy đường dẫn an toàn để lưu file database trên thiết bị
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caro_game.db');

    // Mở database. Nếu file chưa tồn tại, hàm `onCreate` sẽ được gọi.
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // --- Hàm được gọi khi database được tạo lần đầu ---
  Future<void> _onCreate(Database db, int version) async {
    // Câu lệnh SQL để tạo bảng lưu thông tin phiên game
    await db.execute('''
      CREATE TABLE game_session (
        id INTEGER PRIMARY KEY, 
        roomId TEXT NOT NULL,
        sessionToken TEXT NOT NULL,
        myPlayerId INTEGER NOT NULL,
        myPlayerName TEXT NOT NULL
      )
    ''');
  }

  // --- Lưu hoặc Cập nhật phiên game ---
  Future<void> saveSession({
    required String roomId,
    required String sessionToken,
    required int myPlayerId,
    required String myPlayerName,
  }) async {
    final db = await database;
    // Chúng ta chỉ lưu một phiên duy nhất tại một thời điểm.
    // Việc dùng id = 0 và ConflictAlgorithm.replace sẽ giúp:
    // - Nếu chưa có dòng nào, nó sẽ chèn (INSERT) một dòng mới với id = 0.
    // - Nếu đã có dòng id = 0, nó sẽ ghi đè (REPLACE) bằng dữ liệu mới.
    await db.insert('game_session', {
      'id': 0, // ID cố định để luôn ghi đè
      'roomId': roomId,
      'sessionToken': sessionToken,
      'myPlayerId': myPlayerId,
      'myPlayerName': myPlayerName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    print("✅ Game session saved: Room $roomId");
  }

  // --- Lấy phiên game đã lưu ---
  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_session',
      where: 'id = ?',
      whereArgs: [0], // Lấy dòng có id = 0
    );

    if (maps.isNotEmpty) {
      print("ℹ️ Game session found: ${maps.first}");
      return maps.first;
    }
    print("ℹ️ No game session found.");
    return null;
  }

  // --- Xóa phiên game ---
  Future<void> deleteSession() async {
    final db = await database;
    await db.delete(
      'game_session',
      where: 'id = ?',
      whereArgs: [0], // Xóa dòng có id = 0
    );
    print("🗑️ Game session deleted.");
  }
}
