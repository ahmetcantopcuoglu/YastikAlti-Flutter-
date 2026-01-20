class EklenenKurModel {
  final String code;
  final String name;
  final double adet;
  final double alisKuru;
  final DateTime tarih;
  final double guncelKur;

  EklenenKurModel({
    required this.code,
    required this.name,
    required this.adet,
    required this.alisKuru,
    required this.tarih,
    required this.guncelKur,
  });

  double get maliyet => adet * alisKuru;
  double get guncelDeger => adet * guncelKur;

  double get karYuzde {
    if (maliyet == 0) return 0;
    return ((guncelDeger - maliyet) / maliyet) * 100;
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'adet': adet,
        'alisKuru': alisKuru,
        'tarih': tarih.toIso8601String(),
        'guncelKur': guncelKur,
      };

  factory EklenenKurModel.fromJson(Map<String, dynamic> json) => EklenenKurModel(
        code: json['code'],
        name: json['name'],
        adet: json['adet'],
        alisKuru: json['alisKuru'],
        tarih: DateTime.parse(json['tarih']),
        guncelKur: json['guncelKur'],
      );
}
