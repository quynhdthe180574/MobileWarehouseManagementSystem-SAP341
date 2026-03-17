import 'package:flutter/material.dart';

import '../models/stock_model.dart';
import '../services/sap_api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final SapApiService _apiService = SapApiService();

  final TextEditingController _matnrController = TextEditingController();
  final TextEditingController _werksController = TextEditingController();
  final TextEditingController _lgortController = TextEditingController();

  List<StockModel> _stocks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllStocks();
  }

  @override
  void dispose() {
    _matnrController.dispose();
    _werksController.dispose();
    _lgortController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _apiService.fetchAllStocks();
      setState(() {
        _stocks = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Load stocks failed:\n$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _apiService.searchStock(
        matnr: _matnrController.text,
        werks: _werksController.text,
        lgort: _lgortController.text,
      );

      setState(() {
        _stocks = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Search stock failed:\n$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _reset() {
    _matnrController.clear();
    _werksController.clear();
    _lgortController.clear();
    _loadAllStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xem tồn kho theo kho")),
      body: Column(
        children: [
          _buildSearchSection(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _matnrController,
            decoration: InputDecoration(
              labelText: "Material Number (Matnr)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _werksController,
            decoration: InputDecoration(
              labelText: "Plant (Werks)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _lgortController,
            decoration: InputDecoration(
              labelText: "Storage Location (Lgort)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchStock,
                  icon: const Icon(Icons.search),
                  label: const Text("Search"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_stocks.isEmpty) {
      return const Center(child: Text("Không có dữ liệu tồn kho"));
    }

    return RefreshIndicator(
      onRefresh: _loadAllStocks,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final item = _stocks[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.matnr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Plant", item.werks),
                  _infoRow("Storage", item.lgort),
                  _infoRow("Stock Qty", item.labst),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }
}
