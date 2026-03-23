class StockModel {
  final String matnr;
  final String werks;
  final String lgort;
  final String labst;

  StockModel({
    required this.matnr,
    required this.werks,
    required this.lgort,
    required this.labst,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      matnr: json['Matnr']?.toString() ?? '',
      werks: json['Werks']?.toString() ?? '',
      lgort: json['Lgort']?.toString() ?? '',
      labst: json['Labst']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {"Matnr": matnr, "Werks": werks, "Lgort": lgort, "Labst": labst};
  }
}
