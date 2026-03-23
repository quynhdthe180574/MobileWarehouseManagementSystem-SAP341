class GoodsMovementModel {
  final String mblnr;
  final String bwart;
  final String matnr;
  final String werks;
  final String lgort;
  final String menge;

  GoodsMovementModel({
    required this.mblnr,
    required this.bwart,
    required this.matnr,
    required this.werks,
    required this.lgort,
    required this.menge,
  });

  factory GoodsMovementModel.fromJson(Map<String, dynamic> json) {
    return GoodsMovementModel(
      mblnr: json['Mblnr']?.toString() ?? '',
      bwart: json['Bwart']?.toString() ?? '',
      matnr: json['Matnr']?.toString() ?? '',
      werks: json['Werks']?.toString() ?? '',
      lgort: json['Lgort']?.toString() ?? '',
      menge: json['Menge']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Mblnr": mblnr,
      "Bwart": bwart,
      "Matnr": matnr,
      "Werks": werks,
      "Lgort": lgort,
      "Menge": menge,
    };
  }
}
