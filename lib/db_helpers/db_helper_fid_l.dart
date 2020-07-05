import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelperFidL {
  static final _databaseName = "Fidl.db";
  static final _databaseVersion = 1;
  static final table = 'fidl_table';
  static final columnId = 'id';
  static final columnFid = 'fid';
  static final columnFname = 'fname';

  DatabaseHelperFidL._privateConstructor();
  static final DatabaseHelperFidL instance =
      DatabaseHelperFidL._privateConstructor();
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getExternalStorageDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnFid VARCHAR,
            $columnFname TEXT
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  queryfid() async {
    Database db = await DatabaseHelperFidL.instance.database;

    List<String> columnsToSelect = [DatabaseHelperFidL.columnFid];
    String whereString = '${DatabaseHelperFidL.columnId} = ?';
    int rowId = 1;
    List<dynamic> whereArguments = [rowId];
    List<Map> result = await db.query(DatabaseHelperFidL.table,
        columns: columnsToSelect,
        where: whereString,
        whereArgs: whereArguments);

    if (result.length != 0) {
      var fid = result.first.values.single.toString();
      print(fid);
      return fid;
    } else {
      print('QueryFID is null');
      return null;
    }
  }
}
