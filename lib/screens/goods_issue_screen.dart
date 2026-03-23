import 'package:flutter/material.dart';

import '../services/sap_api_service.dart';

class GoodsIssueScreen extends StatefulWidget {
  const GoodsIssueScreen({super.key});

  @override
  State<GoodsIssueScreen> createState() => _GoodsIssueScreenState();
}

class _GoodsIssueScreenState extends State<GoodsIssueScreen> {
  final SapApiService _apiService = SapApiService();
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mblnr = await _apiService.postGoodsMovement(
        matnr: _matnrController.text,
        werks: _werksController.text,
        lgort: _lgortController.text,
        menge: _mengeController.text,
        bwart: '201',
      );

      if (mblnr != null) {
        _showMessage(
          mblnr.toLowerCase() == 'success'
              ? "Xuất kho thành công!"
              : "Xuất kho thành công! Mã: $mblnr",
        );
        _clearForm();
      } else {
        _showMessage("Xuất kho thất bại", isError: true);
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
    _formKey.currentState?.reset();
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _matnrController,
                label: "Material Number (Matnr)",
                hint: "Ví dụ: BTELE101",
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                controller: _werksController,
                label: "Plant (Werks)",
                hint: "Ví dụ: 1000",
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                controller: _lgortController,
                label: "Storage Location (Lgort)",
                hint: "Ví dụ: 0001",
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                controller: _mengeController,
                label: "Quantity (Menge)",
                hint: "Ví dụ: 5",
                keyboardType: TextInputType.number,
                isNumeric: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitGoodsIssue,
                  icon: const Icon(Icons.remove_circle_outline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                  label: Text(
                    _isLoading ? "Processing..." : "Post Goods Issue",
                  ),
                ),
              ),
            ],
          ),
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
            Text("Goods Issue dùng để xuất kho (giảm tồn)."),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Trường này không được để trống";
        }
        if (isNumeric) {
          final n = num.tryParse(value);
          if (n == null || n <= 0) {
            return "Vui lòng nhập số dương hợp lệ";
          }
        }
        return null;
      },
    );
  }
}
