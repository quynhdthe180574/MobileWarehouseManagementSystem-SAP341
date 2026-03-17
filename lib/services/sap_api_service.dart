import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/material_model.dart';
import '../models/stock_model.dart';

class SapApiService {
  // =========================
  // Nếu SAP cần Basic Auth thì mở phần này
  // =========================
  final String username = "dev-379";
  final String password = "03092112";

  String get basicAuth =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Map<String, String> get headers => {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": basicAuth,
  };

  // =========================
  // Parse OData dạng:
  // {
  //   "d": {
  //     "results": [ ... ]
  //   }
  // }
  // =========================
  List<dynamic> _parseODataResults(String responseBody) {
    final data = json.decode(responseBody);
    return data['d']?['results'] ?? [];
  }

  // =========================
  // 1) MATERIAL
  // GET /MaterialSet
  // =========================
  Future<List<MaterialModel>> fetchAllMaterials() async {
    final url = "${ApiConstants.baseUrl}/MaterialSet?\$format=json";

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final results = jsonData['d']['results'] as List;

      return results.map((item) => MaterialModel.fromJson(item)).toList();
    } else {
      throw Exception(
        "Fetch all materials failed: ${response.statusCode}\n${response.body}",
      );
    }
  }

  Future<List<MaterialModel>> searchMaterialByMatnr(String matnr) async {
    final encodedMatnr = matnr.trim().replaceAll("'", "''");

    final url =
        "${ApiConstants.baseUrl}/MaterialSet?\$filter=Matnr eq '$encodedMatnr'&\$format=json";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final results = jsonData['d']['results'] as List;

      return results.map((item) => MaterialModel.fromJson(item)).toList();
    } else {
      throw Exception(
        "Search material failed: ${response.statusCode}\n${response.body}",
      );
    }
  }

  // =========================
  // 2) STOCK
  // GET /StockSet
  // =========================
  Future<List<StockModel>> fetchAllStocks() async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.stockSet}?\$format=json",
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final results = _parseODataResults(response.body);
      return results
          .map((e) => StockModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        "Failed to load stocks: ${response.statusCode}\n${response.body}",
      );
    }
  }

  Future<List<StockModel>> searchStock({
    String matnr = '',
    String werks = '',
    String lgort = '',
  }) async {
    final filters = <String>[];

    if (matnr.trim().isNotEmpty) {
      filters.add("Matnr eq '${matnr.trim()}'");
    }
    if (werks.trim().isNotEmpty) {
      filters.add("Werks eq '${werks.trim()}'");
    }
    if (lgort.trim().isNotEmpty) {
      filters.add("Lgort eq '${lgort.trim()}'");
    }

    String urlString =
        "${ApiConstants.baseUrl}${ApiConstants.stockSet}?\$format=json";

    if (filters.isNotEmpty) {
      urlString =
          "${ApiConstants.baseUrl}${ApiConstants.stockSet}?\$filter=${filters.join(' and ')}&\$format=json";
    }

    // fix escaping for Dart string
    urlString = urlString.replaceAll("\\\$filter", "\$filter");
    urlString = urlString.replaceAll("\\\$format", "\$format");

    final url = Uri.parse(urlString);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final results = _parseODataResults(response.body);
      return results
          .map((e) => StockModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        "Failed to search stock: ${response.statusCode}\n${response.body}",
      );
    }
  }

  // =========================
  // 3) GOODS RECEIPT
  // POST /GoodsMovementSet
  // Bwart = 101
  // =========================
  Future<bool> postGoodsReceipt({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}?\$format=json",
    );

    final body = json.encode({
      "Mblnr": "",
      "Bwart": "101",
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Menge": menge.trim(),
    });

    final response = await http.post(url, headers: headers, body: body);

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // =========================
  // 4) GOODS ISSUE
  // POST /GoodsMovementSet
  // Bwart = 201
  // =========================
  Future<bool> postGoodsIssue({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}?\$format=json",
    );

    final body = json.encode({
      "Mblnr": "",
      "Bwart": "201",
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Menge": menge.trim(),
    });

    final response = await http.post(url, headers: headers, body: body);

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // =========================
  // 5) STOCK UPDATE
  // PUT /StockUpdateSet
  // =========================
  Future<bool> updateStock({
    required String matnr,
    required String werks,
    required String lgort,
    required String labst,
  }) async {
    // OData PUT thường cần key trong URL
    // Nếu key order của metadata khác thì sửa lại đúng thứ tự
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.stockUpdateSet}"
      "(Matnr='${matnr.trim()}',Werks='${werks.trim()}',Lgort='${lgort.trim()}')?\$format=json",
    );

    final body = json.encode({
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Labst": labst.trim(),
    });

    final response = await http.put(url, headers: headers, body: body);

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
