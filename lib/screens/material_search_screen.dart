import 'package:flutter/material.dart';

import '../models/material_model.dart';
import '../services/sap_api_service.dart';

class MaterialSearchScreen extends StatefulWidget {
  const MaterialSearchScreen({super.key});

  @override
  State<MaterialSearchScreen> createState() => _MaterialSearchScreenState();
}

class _MaterialSearchScreenState extends State<MaterialSearchScreen> {
  final SapApiService _apiService = SapApiService();
  final TextEditingController _matnrController = TextEditingController();

  List<MaterialModel> _allMaterials = [];
  List<MaterialModel> _materials = [];

  bool _isLoading = false;
  String _errorMessage = '';

  // Filter dropdown giống ABAP
  String? _selectedMtart;
  String? _selectedMeins;

  List<String> _mtartOptions = [];
  List<String> _meinsOptions = [];

  @override
  void initState() {
    super.initState();
    _loadAllMaterials();
  }

  @override
  void dispose() {
    _matnrController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _apiService.fetchAllMaterials();

      setState(() {
        _allMaterials = data;
        _materials = data;

        // Lấy unique options cho dropdown filter
        _mtartOptions = _allMaterials.map((e) => e.mtart).toSet().toList();
        _meinsOptions = _allMaterials.map((e) => e.meins).toSet().toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Load materials failed:\n$e";
        _allMaterials = [];
        _materials = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Search + filter như ABAP
  Future<void> _searchMaterial() async {
    final keyword = _matnrController.text.trim().toLowerCase();

    setState(() {
      _errorMessage = '';
    });

    final filtered = _allMaterials.where((item) {
      final matchesKeyword =
          keyword.isEmpty ||
          item.matnr.toLowerCase().contains(keyword) ||
          item.mtart.toLowerCase().contains(keyword) ||
          item.meins.toLowerCase().contains(keyword);

      final matchesMtart =
          _selectedMtart == null || item.mtart == _selectedMtart;
      final matchesMeins =
          _selectedMeins == null || item.meins == _selectedMeins;

      return matchesKeyword && matchesMtart && matchesMeins;
    }).toList();

    setState(() {
      _materials = filtered;
      if (filtered.isEmpty) {
        _errorMessage = "Khong tim thay Material phu hop";
      }
    });
  }

  void _reset() {
    _matnrController.clear();
    _selectedMtart = null;
    _selectedMeins = null;

    setState(() {
      _errorMessage = '';
      _materials = _allMaterials;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tra cuu Material")),
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
              hintText: "Vi du: MAT001",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (_) => _searchMaterial(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMtart,
                  decoration: const InputDecoration(
                    labelText: "Material Type (Mtart)",
                    border: OutlineInputBorder(),
                  ),
                  items: _mtartOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMtart = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMeins,
                  decoration: const InputDecoration(
                    labelText: "Base Unit (Meins)",
                    border: OutlineInputBorder(),
                  ),
                  items: _meinsOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMeins = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchMaterial,
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage.isNotEmpty && _materials.isEmpty) {
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

    if (_materials.isEmpty)
      return const Center(child: Text("Khong co du lieu Material"));

    return RefreshIndicator(
      onRefresh: _loadAllMaterials,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final item = _materials[index];

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
                  _infoRow("Created Date", item.ersda),
                  _infoRow("Material Type", item.mtart),
                  _infoRow("Base Unit", item.meins),
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
            width: 120,
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
