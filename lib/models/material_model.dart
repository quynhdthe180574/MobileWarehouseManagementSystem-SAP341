class MaterialModel {
  final String matnr;
  final String ersda;
  final String mtart;
  final String meins;

  MaterialModel({
    required this.matnr,
    required this.ersda,
    required this.mtart,
    required this.meins,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      matnr: json['Matnr']?.toString() ?? '',
      ersda: _parseSapDate(json['Ersda']),
      mtart: json['Mtart']?.toString() ?? '',
      meins: json['Meins']?.toString() ?? '',
    );
  }

  static String _parseSapDate(dynamic value) {
    if (value == null) return '';

    final raw = value.toString();

    // SAP OData hay trả kiểu /Date(1704067200000)/
    final regex = RegExp(r'/Date\((\d+)\)/');
    final match = regex.firstMatch(raw);

    if (match != null) {
      final millis = int.tryParse(match.group(1) ?? '');
      if (millis != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(millis);
        return "${date.year.toString().padLeft(4, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.day.toString().padLeft(2, '0')}";
      }
    }

    return raw;
  }
}
