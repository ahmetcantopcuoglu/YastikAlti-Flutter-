class KurModel {
  final String code;
  final String name;
  final double buying;
  final double selling;

  KurModel({
    required this.code,
    required this.name,
    required this.buying,
    required this.selling,
  });

  factory KurModel.fromJson(String code, Map<String, dynamic> json) {
    return KurModel(
      code: code,
      name: json['Name'] ?? code,
      buying: (json['Buying'] ?? 0).toDouble(),
      selling: (json['Selling'] ?? 0).toDouble(),
    );
  }
}
