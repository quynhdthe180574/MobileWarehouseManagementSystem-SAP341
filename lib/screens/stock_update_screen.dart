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
    final matnr = _matnrController.text.trim();
    final werks = _werksController.text.trim();
    final lgort = _lgortController.text.trim();
    final labst = _labstController.text.trim();

    if (matnr.isEmpty || werks.isEmpty || lgort.isEmpty || labst.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    // Kiểm tra cơ bản số lượng
    if (double.tryParse(labst) == null) {
      _showMessage("Số lượng tồn phải là số hợp lệ", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.updateStock(
        matnr: matnr,
        werks: werks,
        lgort: lgort,
        labst: labst,
      );

      if (success) {
        _showMessage("Cập nhật tồn kho thành công", isError: false);
        _clearForm();
      } else {
        _showMessage("Cập nhật tồn kho thất bại", isError: true);
      }
    } catch (e) {
      _showMessage("Lỗi: $e", isError: true);
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
        duration: const Duration(seconds: 4),
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
            const SizedBox(height: 24),
            _buildTextField(_matnrController, "Material Number (Matnr)"),
            const SizedBox(height: 16),
            _buildTextField(_werksController, "Plant (Werks)"),
            const SizedBox(height: 16),
            _buildTextField(_lgortController, "Storage Location (Lgort)"),
            const SizedBox(height: 16),
            _buildTextField(
              _labstController,
              "New Stock Quantity (Labst)",
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateStock,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading ? "Đang xử lý..." : "Cập nhật tồn kho",
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "PUT /StockUpdateSet",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Điều chỉnh trực tiếp số lượng tồn kho (Labst).\n"
                  "Chỉ dùng khi cần hiệu chỉnh thủ công (không qua movement).",
              style: TextStyle(color: Colors.grey),
            ),
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
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}