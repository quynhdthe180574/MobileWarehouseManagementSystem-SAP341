import 'package:flutter/material.dart';

import '../services/sap_api_service.dart';

class StockUpdateScreen extends StatefulWidget {
  const StockUpdateScreen({super.key});

  @override
  State<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends State<StockUpdateScreen> {
  final SapApiService _apiService = SapApiService();

  final TextEditingController _matnrController = TextEditingController();
  final TextEditingController _werksController = TextEditingController();
  final TextEditingController _lgortController = TextEditingController();
  final TextEditingController _labstController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _matnrController.dispose();
    _werksController.dispose();
    _lgortController.dispose();
    _labstController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    if (_matnrController.text.trim().isEmpty ||
        _werksController.text.trim().isEmpty ||
        _lgortController.text.trim().isEmpty ||
        _labstController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.updateStock(
        matnr: _matnrController.text,
        werks: _werksController.text,
        lgort: _lgortController.text,
        labst: _labstController.text,
      );

      if (success) {
        _showMessage("Cập nhật tồn kho thành công");
        _clearForm();
      } else {
        _showMessage("Cập nhật tồn kho thất bại", isError: true);
      }
    } catch (e) {
      _showMessage(
        "${e.toString().replaceAll("Exception: ", "")}",
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _matnrController.clear();
    _werksController.clear();
    _lgortController.clear();
    _labstController.clear();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cập nhật số lượng tồn")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildTextField(_matnrController, "Material Number (Matnr)"),
            const SizedBox(height: 12),
            _buildTextField(_werksController, "Plant (Werks)"),
            const SizedBox(height: 12),
            _buildTextField(_lgortController, "Storage Location (Lgort)"),
            const SizedBox(height: 12),
            _buildTextField(
              _labstController,
              "New Stock Quantity (Labst)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateStock,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isLoading ? "Processing..." : "Update Stock"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.purple.withOpacity(0.08),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PUT /StockUpdateSet",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text("Dùng để điều chỉnh trực tiếp số lượng tồn kho (Labst)."),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
