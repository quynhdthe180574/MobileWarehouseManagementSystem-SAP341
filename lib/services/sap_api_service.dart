import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/material_model.dart';
import '../models/stock_model.dart';

class SapApiService {
  final String username = "dev-379";
  final String password = "03092112";

  String get basicAuth =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Map<String, String> get headers => {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": basicAuth,
  };

  String? _csrfToken;
  String? _cookie;

  String? _extractCookies(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    final parts = setCookie.split(',');
    final cookies = <String>[];
    for (var part in parts) {
      final firstSemi = part.indexOf(';');
      final cookiePair = firstSemi == -1
          ? part.trim()
          : part.substring(0, firstSemi).trim();
      if (cookiePair.isNotEmpty) {
        cookies.add(cookiePair);
      }
    }
    return cookies.isNotEmpty ? cookies.join('; ') : null;
  }

  Future<void> _fetchCsrfToken() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/?\$format=json");
    final response = await http.get(
      url,
      headers: {"Authorization": basicAuth, "x-csrf-token": "fetch"},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _csrfToken = response.headers['x-csrf-token'];
      _cookie = _extractCookies(response.headers['set-cookie']);
    }
  }

  List<dynamic> _parseODataResults(String responseBody) {
    final data = json.decode(responseBody);
    return data['d']?['results'] ?? [];
  }

  // 1. Lấy danh sách Material
  Future<List<MaterialModel>> fetchAllMaterials() async {
    final url = "${ApiConstants.baseUrl}/MaterialSet?\$format=json";
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final results = jsonData['d']['results'] as List;
      return results.map((item) => MaterialModel.fromJson(item)).toList();
    } else {
      throw Exception("Fetch all materials failed: ${response.statusCode}");
    }
  }

  // 2. Tìm kiếm Stock chuẩn OData (Server-side)
  Future<List<StockModel>> fetchAllStocks({
    String? filter,
    int top = 500,
  }) async {
    final queryParams = {
      "\$format": "json",
      "\$top": top.toString(),
      if (filter != null) "\$filter": filter,
    };

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.stockSet}",
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final results = _parseODataResults(response.body);
      return results
          .map((e) => StockModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load stocks: ${response.statusCode}");
    }
  }

  Future<List<StockModel>> searchStock({
    String matnr = '',
    String werks = '',
    String lgort = '',
  }) async {
    final filters = <String>[];
    if (matnr.trim().isNotEmpty)
      filters.add("Matnr eq '${matnr.trim().toUpperCase()}'");
    if (werks.trim().isNotEmpty)
      filters.add("Werks eq '${werks.trim().toUpperCase()}'");
    if (lgort.trim().isNotEmpty)
      filters.add("Lgort eq '${lgort.trim().toUpperCase()}'");

    final filterString = filters.isNotEmpty ? filters.join(" and ") : null;
    return fetchAllStocks(filter: filterString);
  }

  // 3. Nhập kho (Goods Receipt)
  Future<String?> postGoodsReceipt({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    await _fetchCsrfToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}",
    );
    final body = json.encode({
      "Mblnr": "",
      "Bwart": "101",
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Menge": menge.trim(),
    });

    final postHeaders = Map<String, String>.from(headers);
    if (_csrfToken != null) postHeaders["x-csrf-token"] = _csrfToken!;
    if (_cookie != null) postHeaders["cookie"] = _cookie!;

    final response = await http.post(url, headers: postHeaders, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['d']['Mblnr']?.toString();
    } else {
      throw Exception(_parseError(response.body));
    }
  }

  // 4. Xuất kho (Goods Issue)
  Future<String?> postGoodsIssue({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    await _fetchCsrfToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}",
    );
    final body = json.encode({
      "Mblnr": "",
      "Bwart": "201",
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Menge": menge.trim(),
    });

    final postHeaders = Map<String, String>.from(headers);
    if (_csrfToken != null) postHeaders["x-csrf-token"] = _csrfToken!;
    if (_cookie != null) postHeaders["cookie"] = _cookie!;

    final response = await http.post(url, headers: postHeaders, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['d']['Mblnr']?.toString();
    } else {
      throw Exception(_parseError(response.body));
    }
  }

  // 5. Cập nhật trực tiếp tồn kho (Stock Update)
  Future<bool> updateStock({
    required String matnr,
    required String werks,
    required String lgort,
    required String labst,
  }) async {
    await _fetchCsrfToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.stockUpdateSet}"
      "(Matnr='${matnr.trim()}',Werks='${werks.trim()}',Lgort='${lgort.trim()}')",
    );
    final body = json.encode({
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgort.trim(),
      "Labst": labst.trim(),
    });

    final putHeaders = Map<String, String>.from(headers);
    if (_csrfToken != null) putHeaders["x-csrf-token"] = _csrfToken!;
    if (_cookie != null) putHeaders["cookie"] = _cookie!;

    final response = await http.put(url, headers: putHeaders, body: body);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception(_parseError(response.body));
    }
  }

  // Helper để lấy lỗi từ SAP
  String _parseError(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?['message']?['value'] ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
