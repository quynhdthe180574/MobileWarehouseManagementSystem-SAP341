import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import '../config/api_constants.dart';
import '../models/material_model.dart';
import '../models/stock_model.dart';
import '../models/goods_movement_model.dart';

class SapApiService {
  // ==================================================
  // AUTH - mỗi người đổi username/password của mình
  // ==================================================
  final String username = "dev-399";
  final String password = "Yentrung_25";

  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();

  SapApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
      validateStatus: (status) => true,
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // ==================================================
  // HELPER: Parse OData results từ Response (Dio)
  // ==================================================
  List<dynamic> _parseODataResults(Response response) {
    final data = response.data;
    if (data is Map) return data['d']?['results'] ?? [];
    return [];
  }

  // ==================================================
  // HELPER: Parse OData results từ String (raw body)
  // ==================================================
  List<dynamic> _parseODataResultsFromString(String responseBody) {
    final data = json.decode(responseBody);
    return data['d']?['results'] ?? [];
  }

  // ==================================================
  // HELPER: Format Matnr (đệm số 0 nếu là số thuần túy)
  // ==================================================
  String _formatMatnr(String matnr) {
    final trimmed = matnr.trim().toUpperCase();
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed.padLeft(18, '0');
    }
    return trimmed;
  }

  // ==================================================
  // HELPER: Parse lỗi SAP
  // ==================================================
  String _parseError(dynamic data) {
    try {
      if (data is String) {
        final decoded = json.decode(data);
        return decoded['error']?['message']?['value'] ?? data;
      }
      if (data is Map) {
        return data['error']?['message']?['value'] ?? data.toString();
      }
    } catch (_) {}
    return data.toString();
  }

  // ==================================================
  // FETCH CSRF TOKEN (Dio + CookieJar tự giữ session)
  // ==================================================
  Future<String> _fetchCsrfToken() async {
    final response = await _dio.get(
      "?\$format=json",
      options: Options(headers: {"x-csrf-token": "Fetch"}),
    );
    final token = response.headers.value("x-csrf-token") ?? "";
    print("=== CSRF TOKEN: $token ===");
    return token;
  }

  // ==================================================
  // 1) MATERIAL - GET /MaterialSet
  // ==================================================
  Future<List<MaterialModel>> fetchAllMaterials() async {
    final response = await _dio.get("/MaterialSet?\$format=json");
    if (response.statusCode == 200) {
      final results = (response.data['d']['results'] as List);
      return results.map((item) => MaterialModel.fromJson(item)).toList();
    }
    throw Exception("Fetch all materials failed: ${response.statusCode}");
  }

  Future<List<MaterialModel>> searchMaterialByMatnr(String matnr) async {
    final encodedMatnr = matnr.trim().replaceAll("'", "''");
    final response = await _dio.get(
      "/MaterialSet?\$filter=Matnr eq '$encodedMatnr'&\$format=json",
    );
    if (response.statusCode == 200) {
      final results = (response.data['d']['results'] as List);
      return results.map((item) => MaterialModel.fromJson(item)).toList();
    }
    throw Exception("Search material failed: ${response.statusCode}");
  }

  // ==================================================
  // 2) STOCK - GET /StockSet
  // ==================================================
  Future<List<StockModel>> fetchAllStocks() async {
    final response = await _dio.get(
      "${ApiConstants.stockSet}?\$format=json",
    );
    if (response.statusCode == 200) {
      final results = _parseODataResults(response);
      return results.map((e) => StockModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception("Failed to load stocks: ${response.statusCode}");
  }

  Future<List<StockModel>> searchStock({
    String matnr = '',
    String werks = '',
    String lgort = '',
  }) async {
    final filters = <String>[];
    if (matnr.trim().isNotEmpty) filters.add("Matnr eq '${matnr.trim()}'");
    if (werks.trim().isNotEmpty) filters.add("Werks eq '${werks.trim()}'");
    if (lgort.trim().isNotEmpty) filters.add("Lgort eq '${lgort.trim()}'");

    String path = "${ApiConstants.stockSet}?\$format=json";
    if (filters.isNotEmpty) {
      path = "${ApiConstants.stockSet}?\$filter=${filters.join(' and ')}&\$format=json";
    }

    final response = await _dio.get(path);
    if (response.statusCode == 200) {
      final results = _parseODataResults(response);
      return results.map((e) => StockModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception("Failed to search stock: ${response.statusCode}");
  }

  /// Lấy danh sách stock dạng raw List<dynamic> (tương thích với code cũ dùng http)
  Future<List<dynamic>> getStocks() async {
    final response = await _dio.get(
      "${ApiConstants.stockSet}?\$format=json",
    );
    if (response.statusCode == 200) {
      return _parseODataResults(response);
    }
    throw Exception("Failed to load stocks: ${response.statusCode}");
  }

  // ==================================================
  // 3) GOODS RECEIPT - POST /GoodsMovementSet Bwart=101
  // ==================================================
  Future<bool> postGoodsReceipt({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    final token = await _fetchCsrfToken();
    final response = await _dio.post(
      ApiConstants.goodsMovementSet,
      data: {
        "Mblnr": "",
        "Bwart": "101",
        "Matnr": _formatMatnr(matnr),
        "Werks": werks.trim().toUpperCase(),
        "Lgort": lgort.trim().toUpperCase(),
        "Menge": menge.trim(),
      },
      options: Options(headers: {"x-csrf-token": token}),
    );

    print("=== GOODS RECEIPT ===");
    print("STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.data}");
    print("=====================");

    if (response.statusCode == 201 || response.statusCode == 200) return true;
    throw Exception(_parseError(response.data));
  }

  // ==================================================
  // 4) GOODS ISSUE - POST /GoodsMovementSet Bwart=201
  // ==================================================
  Future<bool> postGoodsIssue({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
  }) async {
    final token = await _fetchCsrfToken();
    final response = await _dio.post(
      ApiConstants.goodsMovementSet,
      data: {
        "Mblnr": "",
        "Bwart": "201",
        "Matnr": _formatMatnr(matnr),
        "Werks": werks.trim().toUpperCase(),
        "Lgort": lgort.trim().toUpperCase(),
        "Menge": menge.trim(),
      },
      options: Options(headers: {"x-csrf-token": token}),
    );

    print("=== GOODS ISSUE ===");
    print("STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.data}");
    print("===================");

    if (response.statusCode == 201 || response.statusCode == 200) return true;
    throw Exception(_parseError(response.data));
  }

  // ==================================================
  // 4b) GOODS MOVEMENT CHUNG - POST /GoodsMovementSet
  // Dùng khi cần gọi với bwart tuỳ ý, trả về Mblnr
  // ==================================================
  Future<String?> postGoodsMovement({
    required String matnr,
    required String werks,
    required String lgort,
    required String menge,
    required String bwart,
  }) async {
    final token = await _fetchCsrfToken();
    final response = await _dio.post(
      ApiConstants.goodsMovementSet,
      data: {
        "Mblnr": "",
        "Bwart": bwart,
        "Matnr": _formatMatnr(matnr),
        "Werks": werks.trim().toUpperCase(),
        "Lgort": lgort.trim().toUpperCase(),
        "Menge": menge.trim(),
      },
      options: Options(headers: {"x-csrf-token": token}),
    );

    print("=== GOODS MOVEMENT (bwart=$bwart) ===");
    print("STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.data}");
    print("======================================");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data;
      if (data is Map) return data['d']?['Mblnr']?.toString();
      return null;
    }
    throw Exception(_parseError(response.data));
  }

  // ==================================================
  // 5) STOCK UPDATE - PUT /StockSet(...)
  // ==================================================
  Future<bool> updateStock({
    required String matnr,
    required String werks,
    required String lgort,
    required String labst,
  }) async {
    final token = await _fetchCsrfToken();
    final formattedMatnr = _formatMatnr(matnr);

    final url =
        "${ApiConstants.stockSet}(Matnr='$formattedMatnr',Werks='${werks.trim().toUpperCase()}',Lgort='${lgort.trim().toUpperCase()}')";

    print("=== PUT URL: $url ===");

    final response = await _dio.put(
      url,
      data: {
        "Matnr": formattedMatnr,
        "Werks": werks.trim().toUpperCase(),
        "Lgort": lgort.trim().toUpperCase(),
        "Labst": labst.trim(),
      },
      options: Options(headers: {"x-csrf-token": token}),
    );

    print("=== UPDATE STOCK ===");
    print("STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.data}");
    print("=====================");

    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception(_parseError(response.data));
  }

  // ==================================================
  // 6) TRANSFER POSTING - POST /GoodsMovementSet Bwart=311
  // Lgort đích truyền qua field Mblnr (ABAP đọc từ đó)
  // ==================================================
  Future<bool> postTransferPosting({
    required String matnr,
    required String werks,
    required String lgortFrom,
    required String lgortTo,
    required String menge,
  }) async {
    final token = await _fetchCsrfToken();
    final response = await _dio.post(
      ApiConstants.goodsMovementSet,
      data: {
        "Mblnr": lgortTo.trim().toUpperCase(),
        "Bwart": "311",
        "Matnr": _formatMatnr(matnr),
        "Werks": werks.trim().toUpperCase(),
        "Lgort": lgortFrom.trim().toUpperCase(),
        "Menge": menge.trim(),
      },
      options: Options(headers: {"x-csrf-token": token}),
    );

    print("=== TRANSFER POSTING ===");
    print("STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.data}");
    print("========================");

    if (response.statusCode == 201 || response.statusCode == 200) return true;
    throw Exception(_parseError(response.data));
  }

  // ==================================================
  // 7) HISTORY - GET /GoodsMovementSet
  // ==================================================
  Future<List<GoodsMovementModel>> fetchMovementHistory({
    String? matnr,
    int maxResults = 100,
  }) async {
    final filters = <String>[];
    if (matnr != null && matnr.trim().isNotEmpty) {
      filters.add("Matnr eq '${matnr.trim()}'");
    }

    String path =
        "${ApiConstants.goodsMovementSet}?\$format=json&\$top=$maxResults&\$orderby=Mblnr desc";
    if (filters.isNotEmpty) {
      path += "&\$filter=${filters.join(' and ')}";
    }

    final response = await _dio.get(path);
    if (response.statusCode == 200) {
      final results = _parseODataResults(response);
      return results
          .map((e) => GoodsMovementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Failed to fetch history: ${response.statusCode}");
  }
}