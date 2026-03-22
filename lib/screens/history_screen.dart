import 'package:flutter/material.dart';
import '../models/goods_movement_model.dart';
import '../services/sap_api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SapApiService _apiService = SapApiService();

  List<GoodsMovementModel> _movements = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _apiService.fetchMovementHistory(
        maxResults: 100, // tăng lên nếu cần nhiều hơn
      );

      setState(() {
        _movements = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Không tải được lịch sử:\n$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDocumentDate(String? mblnr) {
    // Vì không có field thời gian, tạm hiển thị Mblnr làm "ngày" (sẽ thay sau nếu thêm field)
    if (mblnr == null || mblnr.isEmpty) return 'Không có ngày';
    // Có thể cải tiến sau: nếu SAP thêm PostingDate, parse ở đây
    return 'Chứng từ: $mblnr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movements.isEmpty
                ? const Center(
                    child: Text(
                      "Chưa có giao dịch nào",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _movements.length,
                      itemBuilder: (context, index) {
                        final item = _movements[index];
                        final isIssue = item.bwart == '201';
                        final isReceipt = item.bwart == '101';
                        final isTransfer = item.bwart == '311';

                        Color color = Colors.grey;
                        IconData icon = Icons.history;

                        if (isReceipt) {
                          color = Colors.green;
                          icon = Icons.add_box_outlined;
                        } else if (isIssue) {
                          color = Colors.red;
                          icon = Icons.outbox_outlined;
                        } else if (isTransfer) {
                          color = Colors.teal;
                          icon = Icons.swap_horiz;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            title: Text(
                              item.matnr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDocumentDate(item.mblnr),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Loại: ${item.bwart} | SL: ${item.menge} | '
                                  '${item.werks}/${item.lgort}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.bwart,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
