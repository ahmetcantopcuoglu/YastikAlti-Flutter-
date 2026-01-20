import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/add_doviz_model.dart';

class KurStorageService {
  static const String keyPrefix = 'kur_';

  Future<void> saveKur(String code, List<EklenenKurModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    prefs.setString(keyPrefix + code, jsonEncode(jsonList));
  }

  Future<List<EklenenKurModel>> loadKur(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(keyPrefix + code);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => EklenenKurModel.fromJson(e)).toList();
  }
}
