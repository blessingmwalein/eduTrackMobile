import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataBaseService {
  // singleton boilerplate
  static final DataBaseService _databaseService = DataBaseService._internal();

  factory DataBaseService() {
    return _databaseService;
  }
  // singleton boilerplate
  DataBaseService._internal();

  /// file that stores the data on filesystem
  File jsonFile;

  /// Data learned on memory
  Map<String, dynamic> _db = Map<String, dynamic>();
  Map<String, dynamic> get db => this._db;

  /// loads a simple json file.
  Future loadDB() async {
    var tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';

    print(_embPath);
    jsonFile = new File(_embPath);

    if (jsonFile.existsSync()) {
      _db = json.decode(jsonFile.readAsStringSync());
    }
  }

  /// [Name]: name of the new user
  /// [Data]: Face representation for Machine Learning model
  Future saveData(String firstName, String lastName, String password,String userClass,String userParentMobile, List modelData) async {
    String userAndPass = firstName+ ':' +lastName+ ':' + password + ':' + userClass + ':' + userParentMobile;
    _db[userAndPass] = modelData;
    jsonFile.writeAsStringSync(json.encode(_db));
  }

  /// deletes the created users
  cleanDB() {
    this._db = Map<String, dynamic>();
    jsonFile.writeAsStringSync(json.encode({}));
  }
}
