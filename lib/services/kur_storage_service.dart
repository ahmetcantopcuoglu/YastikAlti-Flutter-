import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/add_doviz_model.dart';

class KurStorageService {
  static const String keyPrefix = 'kur_';
  
  // 🔹 HATAYI ÇÖZEN TANIMLAMALAR BURADA:
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- KAYDETME ---
 // KurStorageService içindeki saveKur metodunu şu şekilde güncelle:
Future<void> saveKur(String code, List<EklenenKurModel> list) async {
  final user = _auth.currentUser;

  if (user != null) {
    // ... Firebase kodların aynı kalsın ...
  } else {
    // MİSAFİR (SharedPrefs) KISMI
    final prefs = await SharedPreferences.getInstance();
    
    // Listenin boş gitmediğinden ve Timestamp hatası vermediğinden emin olalım
    final jsonList = list.map((item) {
      final map = item.toJson();
      // ÖNEMLİ: Eğer tarih objesi hala Timestamp ise String'e çevir
      if (map['date'] is Timestamp) {
        map['date'] = (map['date'] as Timestamp).toDate().toIso8601String();
      }
      return map;
    }).toList();

    await prefs.setString(keyPrefix + code, jsonEncode(jsonList));
  }
}

  // --- VERİ ÇEKME ---
  Future<List<EklenenKurModel>> loadKur(String code) async {
    final user = _auth.currentUser;

    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('assets')
          .where('code', isEqualTo: code)
          .get();

      return snapshot.docs
          .map((doc) => EklenenKurModel.fromJson(doc.data()))
          .toList();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(keyPrefix + code);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => EklenenKurModel.fromJson(e)).toList();
    }
  }

  // --- SENKRONİZASYON ---
  Future<void> syncLocalDataToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final categories = ['USD', 'EUR', 'GRA', 'CEYREKALTIN', 'YARIMALTIN', 'TAMALTIN', 
                        'CUMHURIYETALTINI', 'ATAALTIN', '14AYARALTIN', '18AYARALTIN', 
                        '22AYARALTIN', 'IKIBUCUKALTIN', 'BESLIALTIN', 'GREMSEALTIN', 'GUMUS'];
    
    for (var cat in categories) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(keyPrefix + cat);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final localItems = jsonList.map((e) => EklenenKurModel.fromJson(e)).toList();
        
        await saveKur(cat, localItems);
        await prefs.remove(keyPrefix + cat);
      }
    }
  }
}