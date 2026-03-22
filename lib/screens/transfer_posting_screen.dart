import 'package:flutter/material.dart';

import '../services/sap_api_service.dart';

class TransferPostingScreen extends StatefulWidget {
  const TransferPostingScreen({super.key});

  @override
  State<TransferPostingScreen> createState() => _TransferPostingScreenState();
}

class _TransferPostingScreenState extends State<TransferPostingScreen> {
  final SapApiService _apiService = SapApiService();

  final TextEditingController _matnrController = TextEditingController();
  final TextEditingController _werksController = TextEditingController();
  final TextEditingController _lgortFromController = TextEditingController();
  final TextEditingController _lgortToController = TextEditingController();
  final TextEditingController _mengeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _matnrController.dispose();
    _werksController.dispose();
    _lgortFromController.dispose();
    _lgortToController.dispose();
    _mengeController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final matnr = _matnrController.text.trim();
    final werks = _werksController.text.trim();
    final lgortFrom = _lgortFromController.text.trim();
    final lgortTo = _lgortToController.text.trim();
    final menge = _mengeController.text.trim();

    if (matnr.isEmpty ||
        werks.isEmpty ||
        lgortFrom.isEmpty ||
        lgortTo.isEmpty ||
        menge.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin", isError: true);
      return;
    }

    if (lgortFrom == lgortTo) {
      _showMessage("Kho nguồn và kho đích phải khác nhau", isError: true);
      return;
    }

    if (double.tryParse(menge) == null || double.parse(menge) <= 0) {
      _showMessage("Số lượng phải là số dương", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.postTransferPosting(
        matnr: matnr,
        werks: werks,
        lgortFrom: lgortFrom,
        lgortTo: lgortTo,
        menge: menge,
      );

      if (success) {
        _showMessage("Chuyển kho thành công (Movement Type 311)");
        _clearForm();
      } else {
        _showMessage("Chuyển kho thất bại", isError: true);
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
    _lgortFromController.clear();
    _lgortToController.clear();
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
      appBar: AppBar(title: const Text("Chuyển kho (Transfer Posting)")),
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
            _buildTextField(
              _lgortFromController,
              "Từ Storage Location (Lgort)",
            ),
            const SizedBox(height: 16),
            _buildTextField(_lgortToController, "Đến Storage Location (Lgort)"),
            const SizedBox(height: 16),
            _buildTextField(
              _mengeController,
              "Quantity (Menge)",
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitTransfer,
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  _isLoading ? "Đang xử lý..." : "Thực hiện chuyển kho",
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.teal.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Movement Type: 311",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Chuyển vật liệu giữa các kho trong cùng một nhà máy (Plant).\n"
              "Không thay đổi tổng tồn kho toàn plant.",
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
