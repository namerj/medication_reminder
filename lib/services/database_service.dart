import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/advanced_reminder.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medication_reminder.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE medication_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medicationId INTEGER NOT NULL,
          scheduledDate INTEGER NOT NULL,
          scheduledTime TEXT NOT NULL,
          actualTime INTEGER,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (medicationId) REFERENCES medications (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE advanced_reminders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medicationId INTEGER NOT NULL,
          type INTEGER NOT NULL,
          minutesBefore INTEGER NOT NULL DEFAULT 0,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          sound INTEGER NOT NULL DEFAULT 0,
          priority INTEGER NOT NULL DEFAULT 1,
          vibrate INTEGER NOT NULL DEFAULT 1,
          persistentNotification INTEGER NOT NULL DEFAULT 0,
          snoozeMinutes INTEGER NOT NULL DEFAULT 5,
          maxSnoozeCount INTEGER NOT NULL DEFAULT 3,
          customMessage TEXT,
          reminderDays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
          startDate INTEGER,
          endDate INTEGER,
          FOREIGN KEY (medicationId) REFERENCES medications (id)
        )
      ''');
      
      await db.execute('''
        CREATE TABLE reminder_settings(
          id INTEGER PRIMARY KEY,
          enableAdvancedReminders INTEGER NOT NULL DEFAULT 1,
          enableMissedDoseReminders INTEGER NOT NULL DEFAULT 1,
          missedDoseReminderMinutes INTEGER NOT NULL DEFAULT 30,
          enableRefillReminders INTEGER NOT NULL DEFAULT 1,
          refillReminderDays INTEGER NOT NULL DEFAULT 3,
          enableWeeklyReports INTEGER NOT NULL DEFAULT 0,
          enableQuietHours INTEGER NOT NULL DEFAULT 0,
          quietHoursStart TEXT NOT NULL DEFAULT '22:00',
          quietHoursEnd TEXT NOT NULL DEFAULT '07:00'
        )
      ''');
      
      // Insert default settings
      await db.insert('reminder_settings', {
        'id': 1,
        'enableAdvancedReminders': 1,
        'enableMissedDoseReminders': 1,
        'missedDoseReminderMinutes': 30,
        'enableRefillReminders': 1,
        'refillReminderDays': 3,
        'enableWeeklyReports': 0,
        'enableQuietHours': 0,
        'quietHoursStart': '22:00',
        'quietHoursEnd': '07:00',
      });
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER,
        notes TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE TABLE medication_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        scheduledDate INTEGER NOT NULL,
        scheduledTime TEXT NOT NULL,
        actualTime INTEGER,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (medicationId) REFERENCES medications (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE advanced_reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        type INTEGER NOT NULL,
        minutesBefore INTEGER NOT NULL DEFAULT 0,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        sound INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 1,
        vibrate INTEGER NOT NULL DEFAULT 1,
        persistentNotification INTEGER NOT NULL DEFAULT 0,
        snoozeMinutes INTEGER NOT NULL DEFAULT 5,
        maxSnoozeCount INTEGER NOT NULL DEFAULT 3,
        customMessage TEXT,
        reminderDays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        startDate INTEGER,
        endDate INTEGER,
        FOREIGN KEY (medicationId) REFERENCES medications (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE reminder_settings(
        id INTEGER PRIMARY KEY,
        enableAdvancedReminders INTEGER NOT NULL DEFAULT 1,
        enableMissedDoseReminders INTEGER NOT NULL DEFAULT 1,
        missedDoseReminderMinutes INTEGER NOT NULL DEFAULT 30,
        enableRefillReminders INTEGER NOT NULL DEFAULT 1,
        refillReminderDays INTEGER NOT NULL DEFAULT 3,
        enableWeeklyReports INTEGER NOT NULL DEFAULT 0,
        enableQuietHours INTEGER NOT NULL DEFAULT 0,
        quietHoursStart TEXT NOT NULL DEFAULT '22:00',
        quietHoursEnd TEXT NOT NULL DEFAULT '07:00'
      )
    ''');
    
    // Insert default settings
    await db.insert('reminder_settings', {
      'id': 1,
      'enableAdvancedReminders': 1,
      'enableMissedDoseReminders': 1,
      'missedDoseReminderMinutes': 30,
      'enableRefillReminders': 1,
      'refillReminderDays': 3,
      'enableWeeklyReports': 0,
      'enableQuietHours': 0,
      'quietHoursStart': '22:00',
      'quietHoursEnd': '07:00',
    });
  }

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medications');
    return List.generate(maps.length, (i) {
      return Medication.fromMap(maps[i]);
    });
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Medication.fromMap(maps[i]);
    });
  }

  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 打卡记录相关方法
  Future<int> insertMedicationRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('medication_records', record);
  }

  Future<List<Map<String, dynamic>>> getMedicationRecords(int medicationId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    
    return await db.query(
      'medication_records',
      where: 'medicationId = ? AND scheduledDate >= ? AND scheduledDate <= ?',
      whereArgs: [medicationId, startOfDay, endOfDay],
    );
  }

  Future<Map<String, dynamic>?> getMedicationRecord(int medicationId, DateTime date, String time) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    
    final records = await db.query(
      'medication_records',
      where: 'medicationId = ? AND scheduledDate >= ? AND scheduledDate <= ? AND scheduledTime = ?',
      whereArgs: [medicationId, startOfDay, endOfDay, time],
    );
    
    return records.isNotEmpty ? records.first : null;
  }

  Future<int> updateMedicationRecord(int id, Map<String, dynamic> record) async {
    final db = await database;
    return await db.update(
      'medication_records',
      record,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getCompletionStats(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;
    
    return await db.rawQuery('''
      SELECT 
        DATE(scheduledDate / 1000, 'unixepoch') as date,
        COUNT(*) as total,
        SUM(isCompleted) as completed
      FROM medication_records 
      WHERE scheduledDate >= ? AND scheduledDate <= ?
      GROUP BY DATE(scheduledDate / 1000, 'unixepoch')
      ORDER BY date
    ''', [start, end]);
  }

  // 导出所有数据
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    
    // 获取所有用药信息
    final medications = await db.query('medications');
    
    // 获取所有用药记录
    final records = await db.query('medication_records');
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'medications': medications,
      'medicationRecords': records,
    };
  }
  
  // 获取所有用药记录（用于导出）
  Future<List<Map<String, dynamic>>> getAllMedicationRecords() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        mr.*,
        m.name as medicationName,
        m.dosage as medicationDosage
      FROM medication_records mr
      LEFT JOIN medications m ON mr.medicationId = m.id
      ORDER BY mr.scheduledDate DESC, mr.scheduledTime
    ''');
  }
  
  // Advanced Reminders CRUD operations
  Future<int> insertAdvancedReminder(AdvancedReminder reminder) async {
    final db = await database;
    return await db.insert('advanced_reminders', reminder.toMap());
  }

  Future<List<AdvancedReminder>> getAdvancedReminders(int medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'advanced_reminders',
      where: 'medicationId = ?',
      whereArgs: [medicationId],
    );
    return List.generate(maps.length, (i) {
      return AdvancedReminder.fromMap(maps[i]);
    });
  }

  Future<List<AdvancedReminder>> getAllAdvancedReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('advanced_reminders');
    return List.generate(maps.length, (i) {
      return AdvancedReminder.fromMap(maps[i]);
    });
  }

  Future<List<AdvancedReminder>> getEnabledAdvancedReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'advanced_reminders',
      where: 'isEnabled = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return AdvancedReminder.fromMap(maps[i]);
    });
  }

  Future<int> updateAdvancedReminder(AdvancedReminder reminder) async {
    final db = await database;
    return await db.update(
      'advanced_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteAdvancedReminder(int id) async {
    final db = await database;
    return await db.delete(
      'advanced_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAdvancedRemindersByMedication(int medicationId) async {
    final db = await database;
    return await db.delete(
      'advanced_reminders',
      where: 'medicationId = ?',
      whereArgs: [medicationId],
    );
  }

  // Reminder Settings operations
  Future<ReminderSettings> getReminderSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return ReminderSettings.fromMap(maps.first);
    }
    // Return default settings if not found
    return ReminderSettings();
  }

  Future<int> updateReminderSettings(ReminderSettings settings) async {
    final db = await database;
    return await db.update(
      'reminder_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // 清除所有数据
  Future<void> clearAllData() async {
    final db = await database;
    
    // 删除所有高级提醒
    await db.delete('advanced_reminders');
    
    // 删除所有用药记录
    await db.delete('medication_records');
    
    // 删除所有用药信息
    await db.delete('medications');
    
    // 重置提醒设置为默认值
    await db.update('reminder_settings', ReminderSettings().toMap(), where: 'id = ?', whereArgs: [1]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}