import 'package:cloud_firestore/cloud_firestore.dart';

class EklenenKurModel {
  final String code;      // Örn: 'USD' veya 'CEYREKALTIN'
  final String name;      // Firebase'deki 'type' alanı (Örn: 'Altın')
  final double adet;      // Firebase'deki 'amount' alanı
  final double alisKuru;  // Firebase'deki 'cost' alanı
  final DateTime tarih;   // Firebase'deki 'date' alanı
  final double guncelKur; // Yereldeki hesaplamalar için güncel fiyat

  EklenenKurModel({
    required this.code,
    required this.name,
    required this.adet,
    required this.alisKuru,
    required this.tarih,
    required this.guncelKur,
  });

  // 🔹 HomePage'deki "total += item.guncelDeger" hatasını çözen hesaplamalar:
  double get maliyet => adet * alisKuru; 
  double get guncelDeger => adet * guncelKur;

  double get karYuzde {
    if (maliyet == 0) return 0;
    return ((guncelDeger - maliyet) / maliyet) * 100;
  }

  // --- FIREBASE'E KAYDEDERKEN (toJson) ---
Map<String, dynamic> toJson({bool toFirestore = false}) => {
      'code': code,
      'type': name,
      'amount': adet,
      'cost': alisKuru,
      'guncelKur': guncelKur,
      // Firebase'e giderken Timestamp, lokale giderken ISO String
      'date': toFirestore 
          ? Timestamp.fromDate(tarih) 
          : tarih.toIso8601String(), 
      // NOT: tarih değişkeninin kendisi milisaniye içerdiği sürece sorun yok
    };

  // --- FIREBASE VEYA SHARED PREFS'TEN OKURKEN (fromJson) ---
  factory EklenenKurModel.fromJson(Map<String, dynamic> json) {
    return EklenenKurModel(
      code: json['code'] ?? '',
      name: json['type'] ?? (json['name'] ?? ''), 
      // Hem 'amount' hem 'adet' kontrolü yaparak eski yerel kayıtları da kurtarıyoruz:
      adet: (json['amount'] ?? (json['adet'] ?? 0)).toDouble(),
      alisKuru: (json['cost'] ?? (json['alisKuru'] ?? 0)).toDouble(),
      
      // Tarih dönüşümü: Firebase'den gelirse Timestamp, SharedPrefs'ten gelirse String
      tarih: json['date'] != null 
          ? (json['date'] is Timestamp 
              ? (json['date'] as Timestamp).toDate() 
              : DateTime.parse(json['date']))
          : (json['tarih'] != null ? DateTime.parse(json['tarih']) : DateTime.now()),
          
      guncelKur: (json['guncelKur'] ?? 0).toDouble(),
    );
  }
}