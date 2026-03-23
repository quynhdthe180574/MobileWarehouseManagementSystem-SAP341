import 'package:flutter/material.dart';
import 'package:sap_app/services/sap_api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List stocks = [];
  List filteredStocks = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String selectedPlant = "All";
  String selectedStorage = "All";

  @override
  void initState() {
    super.initState();
    loadStocks();
  }

  Future<void> loadStocks() async {
    setState(() {
      isLoading = true;
    });

    try {
      var data = await SapApiService().getStocks();

      setState(() {
        stocks = data;
        filteredStocks = data;
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  /// SEARCH + FILTER
  void applyFilter() {
    String query = searchController.text.toLowerCase();

    var result = stocks.where((stock) {
      final matnr = stock["Matnr"].toString().toLowerCase();
      final werks = stock["Werks"].toString().toLowerCase();
      final lgort = stock["Lgort"].toString().toLowerCase();

      final matchesSearch =
          matnr.contains(query) ||
          werks.contains(query) ||
          lgort.contains(query);

      final matchesPlant =
          selectedPlant == "All" || stock["Werks"] == selectedPlant;

      final matchesStorage =
          selectedStorage == "All" || stock["Lgort"] == selectedStorage;

      return matchesSearch && matchesPlant && matchesStorage;
    }).toList();

    setState(() {
      filteredStocks = result;
    });
  }

  /// Lấy danh sách Plant
  List<String> getPlantList() {
    List<String> plants = stocks
        .map((e) => e["Werks"].toString())
        .toSet()
        .toList();
    plants.sort();
    plants.insert(0, "All");
    return plants;
  }

  /// Lấy danh sách Storage (phụ thuộc Plant)
  List<String> getStorageList() {
    var filtered = selectedPlant == "All"
        ? stocks
        : stocks.where((e) => e["Werks"] == selectedPlant);

    List<String> storages = filtered
        .map((e) => e["Lgort"].toString())
        .toSet()
        .toList();

    storages.sort();
    storages.insert(0, "All");
    return storages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Warehouse Stock"), centerTitle: true),
      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: searchController,
              onChanged: (value) => applyFilter(),
              decoration: InputDecoration(
                hintText: "Search material / plant / storage...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          /// FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 10),

                /// PLANT
                const Text(
                  "Plant:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),

                DropdownButton<String>(
                  value: selectedPlant,
                  items: getPlantList().map((plant) {
                    return DropdownMenuItem(value: plant, child: Text(plant));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlant = value!;
                      selectedStorage = "All"; // reset storage
                    });
                    applyFilter();
                  },
                ),

                const SizedBox(width: 16),

                /// STORAGE
                const Text(
                  "Storage:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),

                DropdownButton<String>(
                  value: selectedStorage,
                  items: getStorageList().map((storage) {
                    return DropdownMenuItem(
                      value: storage,
                      child: Text(storage),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStorage = value!;
                    });
                    applyFilter();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadStocks,
                    child: filteredStocks.isEmpty
                        ? const Center(
                            child: Text(
                              "No stock found",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredStocks.length,
                            itemBuilder: (context, index) {
                              var stock = filteredStocks[index];

                              double qty =
                                  double.tryParse(stock["Labst"].toString()) ??
                                  0;

                              Color stockColor = qty == 0
                                  ? Colors.red
                                  : Colors.green;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.inventory,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    "Material ${stock["Matnr"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Plant: ${stock["Werks"]}"),
                                      Text("Storage: ${stock["Lgort"]}"),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Stock",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        qty.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: stockColor,
                                        ),
                                      ),
                                    ],
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
