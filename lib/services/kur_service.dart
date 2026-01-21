import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kur_model.dart';

class KurService {
  static const String _url = 'https://finans.truncgil.com/v4/today.json';

  static const String _cacheDataKey = 'kur_cache_data';
  static const String _cacheTimeKey = 'kur_cache_time';

  static const int _cacheMinutes = 60;

  Future<List<KurModel>> fetchKurlar() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // ⏱ Cache zamanı kontrolü
    final lastFetchTime = prefs.getInt(_cacheTimeKey);
    final cachedJson = prefs.getString(_cacheDataKey);

    if (lastFetchTime != null && cachedJson != null) {
      final diffMinutes =
          (now - lastFetchTime) / (1500 * 60);

      if (diffMinutes < _cacheMinutes) {
        // ✅ 1 saat dolmamış → cache kullan
        return _parseKurlar(json.decode(cachedJson));
      }
    }

    // 🌐 API’den çekmeyi dene
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode != 200) {
        throw Exception('API Hatası');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      // 📦 Cache’e kaydet
      prefs.setString(_cacheDataKey, json.encode(data));
      prefs.setInt(_cacheTimeKey, now);

      return _parseKurlar(data);
    } catch (e) {
      // ⚠️ API patladıysa cache’e düş
      if (cachedJson != null) {
        return _parseKurlar(json.decode(cachedJson));
      }

      // ❌ Cache de yoksa gerçek hata
      rethrow;
    }
  }

  /// API ve cache için ortak parse fonksiyonu
  List<KurModel> _parseKurlar(Map<String, dynamic> data) {
    final List<String> selectedCodes = [
      'USD',
      'EUR',
      'GRA',
      'CEYREKALTIN',
      'YARIMALTIN',
      'TAMALTIN',
      "CUMHURIYETALTINI",
      "ATAALTIN",
      "14AYARALTIN",
      "18AYARALTIN",
      "22AYARALTIN",
      "IKIBUCUKALTIN",
      "BESLIALTIN",
      "GREMSEALTIN",
      'GUMUS',

    ];

    List<KurModel> list = [];

    for (var code in selectedCodes) {
      if (data.containsKey(code)) {
        list.add(KurModel.fromJson(code, data[code]));
      }
    }

    return list;
  }

  /// 🔄 Manuel yenileme için (Refresh butonu)
  Future<void> forceRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTimeKey);
  }
}
