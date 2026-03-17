import 'package:flutter/material.dart';

import '../services/sap_api_service.dart';

class GoodsIssueScreen extends StatefulWidget {
  const GoodsIssueScreen({super.key});

  @override
  State<GoodsIssueScreen> createState() => _GoodsIssueScreenState();
}

class _GoodsIssueScreenState extends State<GoodsIssueScreen> {
  final SapApiService _apiService = SapApiService();

  final TextEditingController _matnrController = TextEditingController();
  final TextEditingController _werksController = TextEditingController();
  final TextEditingController _lgortController = TextEditingController();
  final TextEditingController _mengeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _matnrController.dispose();
    _werksController.dispose();
    _lgortController.dispose();
    _mengeController.dispose();
    super.dispose();
  }

  Future<void> _submitGoodsIssue() async {
    if (_matnrController.text.trim().isEmpty ||
        _werksController.text.trim().isEmpty ||
        _lgortController.text.trim().isEmpty ||
        _mengeController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.postGoodsIssue(
        matnr: _matnrController.text,
        werks: _werksController.text,
        lgort: _lgortController.text,
        menge: _mengeController.text,
      );

      if (success) {
        _showMessage("Goods Issue thành công (Bwart = 201)");
        _clearForm();
      } else {
        _showMessage("Goods Issue thất bại", isError: true);
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
    _mengeController.clear();
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
      appBar: AppBar(title: const Text("Xuất kho (Goods Issue)")),
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
              _mengeController,
              "Quantity (Menge)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitGoodsIssue,
                icon: const Icon(Icons.outbox_outlined),
                label: Text(_isLoading ? "Processing..." : "Post Goods Issue"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.red.withOpacity(0.08),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Movement Type: 201",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text("Goods Issue dùng để giảm tồn kho."),
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
