import 'package:flutter/material.dart';
import 'theme.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  int _selectedTabIndex = 0;

  // --- STANDARDS ---
  final double _standardGoldPrice = 399.95; 
  final double _moneyNisab = 33996.00; 
  final double _urufKeptGold = 85.0;    
  final double _urufWornGold = 800.0;   

  // --- CONTROLLERS ---
  final TextEditingController _monthlySalaryCtrl = TextEditingController();
  final TextEditingController _otherIncomeCtrl = TextEditingController();
  final TextEditingController _monthlyCarumanCtrl = TextEditingController();
  
  final List<Map<String, TextEditingController>> _bankAccounts = [
    {'name': TextEditingController(text: "Account 1"), 'balance': TextEditingController()}
  ];
  
  final List<Map<String, dynamic>> _goldItems = [
    {'name': TextEditingController(), 'weight': TextEditingController(), 'isWorn': false}
  ];

  // --- ZIKIR DATA ---
  final List<Map<String, String>> _morningZikir = [
    {"ar": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ", "en": "We have reached the morning and at this very time unto Allah belongs all sovereignty."},
    {"ar": "اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا", "en": "O Allah, by your leave we have reached the morning and by Your leave we have reached the evening."},
    {"ar": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "en": "Glory be to Allah and His is the praise. (100x)"},
  ];
  
  // --- INDEPENDENT TOTALS ---
  double _zakatPendapatan = 0.0;
  double _zakatSimpanan = 0.0;
  double _zakatEmas = 0.0;

  double _parse(String text) {
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  void _runLiveCalculation() {
    setState(() {
      // 1. PENDAPATAN
      double yearlyIncome = (_parse(_monthlySalaryCtrl.text) * 12) + _parse(_otherIncomeCtrl.text);
      if (yearlyIncome >= _moneyNisab) {
        double totalZakatOwed = yearlyIncome * 0.025;
        double carumanAdjustment = (_parse(_monthlyCarumanCtrl.text) * 0.025);
        double calc = totalZakatOwed - carumanAdjustment;
        _zakatPendapatan = calc < 0 ? 0.0 : calc;
      } else {
        _zakatPendapatan = 0.0;
      }

      // 2. SIMPANAN
      double totalBalance = 0.0;
      for (var acc in _bankAccounts) totalBalance += _parse(acc['balance']!.text);
      _zakatSimpanan = (totalBalance >= _moneyNisab) ? (totalBalance * 0.025) : 0.0;

      // 3. EMAS
      double tempGoldZakat = 0.0;
      for (var item in _goldItems) {
        double weight = _parse(item['weight']!.text);
        double threshold = item['isWorn'] ? _urufWornGold : _urufKeptGold;
        if (weight >= threshold) {
          tempGoldZakat += (weight * _standardGoldPrice) * 0.025;
        }
      }
      _zakatEmas = tempGoldZakat;
    });
  }

  void _clearAll() {
    _monthlySalaryCtrl.clear();
    _otherIncomeCtrl.clear();
    _monthlyCarumanCtrl.clear();
    for (var acc in _bankAccounts) { acc['balance']!.clear(); acc['name']!.clear(); }
    for (var item in _goldItems) item['weight']!.clear();
    setState(() {
      _zakatPendapatan = 0.0;
      _zakatSimpanan = 0.0;
      _zakatEmas = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Spiritual Tools"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _clearAll)],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildTabNavigation(),
          const Divider(height: 30),
          Expanded(child: SingleChildScrollView(child: _buildCurrentView())),
          if (_selectedTabIndex != 0) _buildCalculationFooter(),
        ],
      ),
    );
  }

  // --- VIEWS ---
  Widget _buildCurrentView() {
    switch (_selectedTabIndex) {
      case 0: return _zikirView();
      case 1: return _pendapatanView();
      case 2: return _simpananView();
      case 3: return _emasView();
      default: return const Center(child: Text("Select a category"));
    }
  }

  Widget _zikirView() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _morningZikir.length,
    itemBuilder: (context, index) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Text(_morningZikir[index]['ar']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        const SizedBox(height: 10),
        Text(_morningZikir[index]['en']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
      ]),
    ),
  );

  Widget _pendapatanView() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: Column(children: [
      _field("Gaji Kasar Bulanan", _monthlySalaryCtrl, isRM: true),
      _field("Pendapatan Lain (Setahun)", _otherIncomeCtrl, isRM: true),
      _field("Caruman Zakat (Setahun)", _monthlyCarumanCtrl, isRM: true),
    ]),
  );

  Widget _simpananView() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: Column(children: [
      ..._bankAccounts.asMap().entries.map((e) => _itemCard(title: "Bank Info", onDelete: _bankAccounts.length > 1 ? () => setState(() { _bankAccounts.removeAt(e.key); _runLiveCalculation(); }) : null, children: [
        _field("Nama Bank (e.g. ASB/Maybank)", e.value['name']!),
        _field("Baki Terendah Setahun", e.value['balance']!, isRM: true),
      ])),
      TextButton.icon(onPressed: () => setState(() => _bankAccounts.add({'name': TextEditingController(), 'balance': TextEditingController()})), icon: const Icon(Icons.add), label: const Text("Tambah Simpanan"))
    ]),
  );

  Widget _emasView() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: Column(children: [
      ..._goldItems.asMap().entries.map((e) => _itemCard(title: "Item Emas", onDelete: _goldItems.length > 1 ? () => setState(() { _goldItems.removeAt(e.key); _runLiveCalculation(); }) : null, children: [
        Row(children: [
          _toggle(label: "Simpan", active: !e.value['isWorn'], onTap: () { setState(() => e.value['isWorn'] = false); _runLiveCalculation(); }),
          const SizedBox(width: 8),
          _toggle(label: "Hias", active: e.value['isWorn'], onTap: () { setState(() => e.value['isWorn'] = true); _runLiveCalculation(); }),
        ]),
        const SizedBox(height: 10),
        _field("Berat (Gram)", e.value['weight']!, suffix: "g"),
      ])),
      TextButton.icon(onPressed: () => setState(() => _goldItems.add({'name': TextEditingController(), 'weight': TextEditingController(), 'isWorn': false})), icon: const Icon(Icons.add), label: const Text("Tambah Emas"))
    ]),
  );

  // --- FOOTER ---
  Widget _buildCalculationFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _resRow("Zakat Pendapatan", _zakatPendapatan),
        _resRow("Zakat Simpanan", _zakatSimpanan),
        _resRow("Zakat Emas", _zakatEmas),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("TOTAL BAYARAN", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("RM ${(_zakatPendapatan + _zakatSimpanan + _zakatEmas).toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ]),
      ]),
    );
  }

  Widget _resRow(String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      Text("RM ${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: amount > 0 ? FontWeight.bold : FontWeight.normal)),
    ]),
  );

  // --- HELPERS ---
  Widget _field(String l, TextEditingController c, {bool isRM = false, String? suffix}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      onChanged: (_) => _runLiveCalculation(),
      keyboardType: suffix == "g" || isRM ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: l, prefixText: isRM ? "RM " : null, suffixText: suffix, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );

  Widget _itemCard({required String title, VoidCallback? onDelete, required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
    child: Column(children: [
      if (onDelete != null) Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onDelete)),
      ...children
    ]),
  );

  Widget _toggle({required String label, required bool active, required VoidCallback onTap}) => Expanded(
    child: InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? AppTheme.primaryGreen : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), alignment: Alignment.center, child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)))),
  );

  Widget _buildTabNavigation() => SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(children: ["Zikir", "Pendapatan", "Simpanan", "Emas"].asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _selectedTabIndex == e.key, onSelected: (s) => setState(() => _selectedTabIndex = e.key), selectedColor: AppTheme.primaryGreen, labelStyle: TextStyle(color: _selectedTabIndex == e.key ? Colors.white : Colors.black87)))).toList()));
}