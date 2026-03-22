import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/material_model.dart';
import '../models/stock_model.dart';
import '../models/goods_movement_model.dart';
import '../models/goods_movement_model.dart';

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

  String? _formatMatnr(String? matnr) {
    if (matnr == null || matnr.trim().isEmpty) return matnr;
    String trimmed = matnr.trim().toUpperCase();
    // Nếu là số thuần túy, đệm thêm số 0 cho đủ 18 ký tự (Chuẩn SAP MATNR)
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed.padLeft(18, '0');
    }
    return trimmed;
  }

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

  // 2. Tìm kiếm Stock chuẩn OData (Server-side)
  Future<List<dynamic>> getStocks() async {
    final url = "${ApiConstants.baseUrl}/StockSet?\$format=json";
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["d"]["results"];
    } else {
      throw Exception("Failed to load stocks: ${response.statusCode}");
    }
  }

  // 3. Nhập/Xuất kho (Goods Movement - Dùng chung)
  Future<String?> postGoodsMovement({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
    required String bwart,
  }) async {
    await _fetchCsrfToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}",
    );
    final body = json.encode({
      "Mblnr": "",
      "Bwart": bwart,
      "Matnr": _formatMatnr(matnr),
      "Werks": werks.trim().toUpperCase(),
      "Lgort": lgort.trim().toUpperCase(),
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

  // =========================
  // 6) TRANSFER POSTING (Chuyển kho)
  // POST /GoodsMovementSet
  // Bwart = 311
  // =========================
  Future<bool> postTransferPosting({
    required String matnr,
    required String werks,
    required String lgortFrom,
    required String lgortTo,
    required String menge,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}?\$format=json",
    );

    final body = json.encode({
      "Mblnr": "",
      "Bwart": "311",
      "Matnr": matnr.trim(),
      "Werks": werks.trim(),
      "Lgort": lgortFrom.trim(),
      "Lgort_Dest": lgortTo
          .trim(), // nếu SAP không nhận field này, thử đổi thành "MoveToLgort" hoặc hỏi team SAP
      "Menge": menge.trim(),
    });

    final response = await http.post(url, headers: headers, body: body);

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // =========================
  // 7) HISTORY - Lấy lịch sử giao dịch
  // GET /GoodsMovementSet
  // Sort theo Mblnr desc (vì không có field thời gian)
  // =========================
  Future<List<GoodsMovementModel>> fetchMovementHistory({
    String? matnr,
    int maxResults = 100,
  }) async {
    final filters = <String>[];

    if (matnr != null && matnr.trim().isNotEmpty) {
      filters.add("Matnr eq '${matnr.trim()}'");
    }

    String urlString =
        "${ApiConstants.baseUrl}${ApiConstants.goodsMovementSet}"
        "?\$format=json&\$top=$maxResults&\$orderby=Mblnr desc";

    if (filters.isNotEmpty) {
      urlString += "&\$filter=${filters.join(' and ')}";
    }

    final url = Uri.parse(urlString);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final results = _parseODataResults(response.body);
      return results
          .map((e) => GoodsMovementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        "Failed to fetch history: ${response.statusCode}\n${response.body}",
      );
    }
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
