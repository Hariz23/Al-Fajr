import 'package:flutter/material.dart';
import 'theme.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  int _selectedTabIndex = 0; // 0: Zikir, 1: Savings, 2: Gold, 3: Debts

  final TextEditingController _savingsController = TextEditingController();
  final TextEditingController _goldController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();
  double _totalZakat = 0.0;

  void _calculateZakat() {
    double savings = double.tryParse(_savingsController.text) ?? 0;
    double gold = double.tryParse(_goldController.text) ?? 0;
    double debts = double.tryParse(_debtController.text) ?? 0;
    double net = (savings + gold) - debts;
    setState(() => _totalZakat = net > 0 ? net * 0.025 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zakat & Morning Zikir")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // --- THE BUTTON TABS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _navButton("Morning Zikir", 0),
                _navButton("Savings", 1),
                _navButton("Gold & Silver", 2),
                _navButton("Debts", 3),
              ],
            ),
          ),

          const Divider(height: 40),

          // --- CONTENT AREA ---
          Expanded(
            child: _buildCurrentView(),
          ),

          // --- THE BLACK CALCULATION BUTTON ---
          if (_selectedTabIndex != 0) _buildCalculationFooter(),
        ],
      ),
    );
  }

  Widget _navButton(String label, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedTabIndex = index),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          side: BorderSide(color: isSelected ? AppTheme.primaryGreen : Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedTabIndex) {
      case 0: return _morningZikirView();
      case 1: return _inputField("Total Savings", "Cash in bank/hand", _savingsController);
      case 2: return _inputField("Gold & Silver", "Current market value", _goldController);
      case 3: return _inputField("Deductible Debts", "Money owed to others", _debtController);
      default: return Container();
    }
  }

Widget _morningZikirView() {
  final List<Map<String, String>> morningAdhkar = [
    {
      "title": "Ayatul Kursi",
      "arabic": "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...",
      "benefit": "Protection from Jinns until evening."
    },
    {
      "title": "Al-Ikhlas, Al-Falaq, An-Nas",
      "arabic": "قُلْ هُوَ اللَّهُ أَحَدٌ ... (3x)",
      "benefit": "Sufficient for you in all matters."
    },
    {
      "title": "Sayyidul Istighfar",
      "arabic": "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ...",
      "benefit": "The best way to ask for forgiveness."
    }
  ];

  return ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: morningAdhkar.length,
    itemBuilder: (context, index) {
      return Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(morningAdhkar[index]['title']!, 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 10),
              Text(
                morningAdhkar[index]['arabic']!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 20, fontFamily: 'Arabic', height: 1.5),
              ),
              const Divider(height: 30),
              Text(morningAdhkar[index]['benefit']!, 
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _inputField(String title, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              prefixText: "RM ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationFooter() {
    return Container(
      padding: const EdgeInsets.all(25),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Zakat Payable:", style: TextStyle(fontSize: 16)),
              Text("RM ${_totalZakat.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _calculateZakat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Your wireframe's black button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("CALCULATE ZAKAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}