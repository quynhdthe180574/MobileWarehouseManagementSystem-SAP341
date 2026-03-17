import 'package:flutter/material.dart';

import 'material_search_screen.dart';
import 'stock_screen.dart';
import 'goods_receipt_screen.dart';
import 'goods_issue_screen.dart';
import 'stock_update_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menus = [
      _MenuItem(
        title: "Tra cứu Material",
        subtitle: "GET /MaterialSet",
        icon: Icons.inventory_2_outlined,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaterialSearchScreen()),
          );
        },
      ),
      _MenuItem(
        title: "Xem tồn kho theo kho",
        subtitle: "GET /StockSet",
        icon: Icons.warehouse_outlined,
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockScreen()),
          );
        },
      ),
      _MenuItem(
        title: "Nhập kho (Goods Receipt)",
        subtitle: "POST /GoodsMovementSet (101)",
        icon: Icons.add_box_outlined,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoodsReceiptScreen()),
          );
        },
      ),
      _MenuItem(
        title: "Xuất kho (Goods Issue)",
        subtitle: "POST /GoodsMovementSet (201)",
        icon: Icons.outbox_outlined,
        color: Colors.red,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoodsIssueScreen()),
          );
        },
      ),
      _MenuItem(
        title: "Cập nhật số lượng tồn",
        subtitle: "PUT /StockUpdateSet",
        icon: Icons.edit_note_outlined,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockUpdateScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("SAP Stock Management"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final item = menus[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: item.color.withOpacity(0.15),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(item.subtitle),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
              onTap: item.onTap,
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
