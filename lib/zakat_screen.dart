import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';
import 'zakat_calculator.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // Reference values
  final _nisabController = TextEditingController(text: '33996.00');
  final _goldPriceController = TextEditingController(text: '399.95');
  final _silverPriceController = TextEditingController(text: '4.50');
  final _wornUrufController = TextEditingController(
    text: ZakatCalculator.wornGoldThresholdGrams.toStringAsFixed(0),
  );

  // Income - base
  final _monthlySalaryController = TextEditingController();
  final _otherAnnualIncomeController = TextEditingController();
  final _zakatDeductedController = TextEditingController();

  // Income - reliefs (detailed method only)
  final _selfReliefController = TextEditingController();
  final _spouseReliefController = TextEditingController();
  final _childReliefController = TextEditingController();
  final _numberOfSpousesController = TextEditingController(text: '0');
  final _numberOfChildrenController = TextEditingController(text: '0');
  final _parentSupportController = TextEditingController();
  final _educationController = TextEditingController();
  final _medicalController = TextEditingController();
  final _tabungHajiController = TextEditingController();
  final _kwspController = TextEditingController();

  IncomeCalculationMethod _incomeMethod = IncomeCalculationMethod.simple;

  final List<_SavingsEntry> _savings = [_SavingsEntry(named: 'Account 1')];
  final List<_GoldEntry> _goldItems = [_GoldEntry()];
  final List<_SilverEntry> _silverItems = [_SilverEntry()];

  String? _selectedState;

  int _section = 0;
  double _incomeZakat = 0;
  double _savingsZakat = 0;
  double _goldZakat = 0;
  double _silverZakat = 0;

  double get _total => _incomeZakat + _savingsZakat + _goldZakat + _silverZakat;
  double get _nisab => _parse(_nisabController.text);
  double get _goldPrice => _parse(_goldPriceController.text);
  double get _silverPrice => _parse(_silverPriceController.text);
  double get _wornUruf => _parse(_wornUrufController.text);
  StateZakatConfig? get _stateConfig =>
      _selectedState != null ? ZakatCalculator.states[_selectedState] : null;

  @override
  void dispose() {
    _nisabController.dispose();
    _goldPriceController.dispose();
    _silverPriceController.dispose();
    _wornUrufController.dispose();
    _monthlySalaryController.dispose();
    _otherAnnualIncomeController.dispose();
    _zakatDeductedController.dispose();
    _selfReliefController.dispose();
    _spouseReliefController.dispose();
    _childReliefController.dispose();
    _numberOfSpousesController.dispose();
    _numberOfChildrenController.dispose();
    _parentSupportController.dispose();
    _educationController.dispose();
    _medicalController.dispose();
    _tabungHajiController.dispose();
    _kwspController.dispose();
    for (final entry in _savings) {
      entry.dispose();
    }
    for (final entry in _goldItems) {
      entry.dispose();
    }
    for (final entry in _silverItems) {
      entry.dispose();
    }
    super.dispose();
  }

  double _parse(String input) {
    var normalized = input.trim().replaceAll(RegExp(r'[^0-9,.]'), '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',')) {
      final parts = normalized.split(',');
      final looksGrouped = parts.length > 2 || parts.last.length == 3;
      normalized = looksGrouped
          ? normalized.replaceAll(',', '')
          : normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }

  int _parseInt(String input) => int.tryParse(input.trim()) ?? 0;

  /// Applies the selected state's default reliefs and gold method.
  /// Only overwrites relief fields that are still empty or match the
  /// previously-applied defaults, so we don't clobber values the user
  /// has already typed in.
  void _applyStateDefaults(StateZakatConfig? previous, StateZakatConfig next) {
    void maybeReplace(TextEditingController c, double? oldDefault, double newDefault) {
      final current = _parse(c.text);
      final isEmpty = c.text.trim().isEmpty;
      final matchesOldDefault = oldDefault != null && current == oldDefault;
      if (isEmpty || matchesOldDefault) {
        c.text = newDefault.toStringAsFixed(0);
      }
    }

    maybeReplace(_selfReliefController, previous?.selfRelief, next.selfRelief);
    maybeReplace(_spouseReliefController, previous?.spouseRelief, next.spouseRelief);
    maybeReplace(_childReliefController, previous?.childRelief, next.childRelief);
  }

  void _calculate() {
    // Default to the excess/Selangor-style worn-gold method if no state
    // is picked yet, since that's the more common rule nationally.
    final activeGoldMethod = _stateConfig?.wornGoldMethod ?? WornGoldMethod.excess;

    var goldZakat = 0.0;
    for (final item in _goldItems) {
      goldZakat += ZakatCalculator.goldItem(
        weightGrams: _parse(item.weightController.text),
        pricePerGram: _goldPrice,
        isWorn: item.isWorn,
        wornUrufGrams: _wornUruf,
        wornMethod: activeGoldMethod,
      );
    }

    var silverZakat = 0.0;
    for (final item in _silverItems) {
      silverZakat += ZakatCalculator.silverItem(
        weightGrams: _parse(item.weightController.text),
        pricePerGram: _silverPrice,
      );
    }

    setState(() {
      _incomeZakat = ZakatCalculator.income(
        monthlySalary: _parse(_monthlySalaryController.text),
        otherAnnualIncome: _parse(_otherAnnualIncomeController.text),
        nisab: _nisab,
        method: _incomeMethod,
        zakatAlreadyDeducted: _parse(_zakatDeductedController.text),
        selfRelief: _parse(_selfReliefController.text),
        numberOfSpouses: _parseInt(_numberOfSpousesController.text),
        spouseReliefPerSpouse: _parse(_spouseReliefController.text),
        numberOfChildren: _parseInt(_numberOfChildrenController.text),
        childReliefPerChild: _parse(_childReliefController.text),
        parentSupport: _parse(_parentSupportController.text),
        education: _parse(_educationController.text),
        medical: _parse(_medicalController.text),
        tabungHaji: _parse(_tabungHajiController.text),
        kwspContribution: _parse(_kwspController.text),
      );
      _savingsZakat = ZakatCalculator.savings(
        lowestAnnualBalances: _savings.map(
          (entry) => _parse(entry.balanceController.text),
        ),
        nisab: _nisab,
      );
      _goldZakat = goldZakat;
      _silverZakat = silverZakat;
    });
  }

  Future<void> _confirmReset(LanguageProvider lang) async {
    final confirmed = await showDestructiveConfirmation(
      context,
      title: lang.getText('Clear calculator?', 'Kosongkan kalkulator?'),
      message: lang.getText(
        'All entered amounts will be removed.',
        'Semua amaun yang dimasukkan akan dipadam.',
      ),
      confirmLabel: lang.getText('Clear', 'Kosongkan'),
      cancelLabel: lang.getText('Cancel', 'Batal'),
    );
    if (!confirmed) return;

    _monthlySalaryController.clear();
    _otherAnnualIncomeController.clear();
    _zakatDeductedController.clear();
    _selfReliefController.clear();
    _spouseReliefController.clear();
    _childReliefController.clear();
    _numberOfSpousesController.text = '0';
    _numberOfChildrenController.text = '0';
    _parentSupportController.clear();
    _educationController.clear();
    _medicalController.clear();
    _tabungHajiController.clear();
    _kwspController.clear();
    setState(() {
      _selectedState = null;
      _incomeMethod = IncomeCalculationMethod.simple;
    });
    for (final entry in _savings.skip(1)) {
      entry.dispose();
    }
    for (final item in _goldItems.skip(1)) {
      item.dispose();
    }
    for (final item in _silverItems.skip(1)) {
      item.dispose();
    }
    _savings
      ..removeRange(1, _savings.length)
      ..first.balanceController.clear();
    _goldItems
      ..removeRange(1, _goldItems.length)
      ..first.weightController.clear();
    _silverItems
      ..removeRange(1, _silverItems.length)
      ..first.weightController.clear();
    setState(() {
      _incomeZakat = 0;
      _savingsZakat = 0;
      _goldZakat = 0;
      _silverZakat = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('Zakat estimate', 'Anggaran zakat'),
      subtitle: lang.getText(
        'Calculated based on state fatwa',
        'Dikira berdasarkan fatwa negeri',
      ),
      showBackButton: true,
      trailing: AppIconButton(
        icon: CupertinoIcons.refresh,
        label: lang.getText('Clear calculator', 'Kosongkan kalkulator'),
        onPressed: () => _confirmReset(lang),
      ),
      child: Column(
        children: [
          _TotalCard(
            total: _total,
            income: _incomeZakat,
            savings: _savingsZakat,
            gold: _goldZakat,
            silver: _silverZakat,
            lang: lang,
          ),
          const SizedBox(height: 16),
          _stateSelectionCard(lang),
          const SizedBox(height: 12),
          _referenceCard(lang),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _section,
              thumbColor: AppTheme.surface,
              backgroundColor: AppTheme.surfaceMuted,
              children: {
                0: _segment(lang.getText('Income', 'Pendapatan')),
                1: _segment(lang.getText('Savings', 'Simpanan')),
                2: _segment(lang.getText('Gold', 'Emas')),
                3: _segment(lang.getText('Silver', 'Perak')),
              },
              onValueChanged: (value) {
                if (value != null) setState(() => _section = value);
              },
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_section) {
              0 => _incomeForm(lang),
              1 => _savingsForm(lang),
              2 => _goldForm(lang),
              _ => _silverForm(lang),
            },
          ),
        ],
      ),
    );
  }

  Widget _segment(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  Widget _stateSelectionCard(LanguageProvider lang) {
    final config = _stateConfig;
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('Select your state', 'Pilih negeri anda'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedState,
                hint: Text(
                  lang.getText('State (optional)', 'Negeri (pilihan)'),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                items: ZakatCalculator.states.keys.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue == null) return;
                  final previous = _stateConfig;
                  setState(() {
                    _selectedState = newValue;
                    _applyStateDefaults(previous, ZakatCalculator.states[newValue]!);
                  });
                  _calculate();
                },
              ),
            ),
          ),
          if (config != null) ...[
            const SizedBox(height: 10),
            Text(
              lang.getText(
                'Reliefs and the worn-gold rule below are defaults for ${config.authority} — confirm current figures on their site before paying.',
                'Pelepasan dan kaedah emas dipakai di bawah adalah lalai bagi ${config.authority} — sahkan angka semasa di laman mereka sebelum membayar.',
              ),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _referenceCard(LanguageProvider lang) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(
          CupertinoIcons.slider_horizontal_3,
          color: AppTheme.primaryGreen,
        ),
        title: Text(
          lang.getText('Reference values', 'Nilai rujukan'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          lang.getText(
            'Editable because rates change',
            'Boleh diubah kerana kadar berubah',
          ),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        children: [
          _moneyField(
            label: lang.getText('Money nisab', 'Nisab wang'),
            controller: _nisabController,
          ),
          _moneyField(
            label: lang.getText('Gold price per gram', 'Harga emas per gram'),
            controller: _goldPriceController,
          ),
          _moneyField(
            label: lang.getText('Silver price per gram', 'Harga perak per gram'),
            controller: _silverPriceController,
          ),
          _numberField(
            label: lang.getText('Worn gold uruf', 'Uruf emas dipakai'),
            controller: _wornUrufController,
            suffix: 'g',
          ),
        ],
      ),
    );
  }

  Widget _incomeForm(LanguageProvider lang) {
    final isDetailed = _incomeMethod == IncomeCalculationMethod.detailed;
    return AppSurface(
      key: const ValueKey('income'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeading(
            lang.getText('Annual income', 'Pendapatan tahunan'),
            lang.getText(
              'Gross yearly income is assessed at 2.5% once it clears the nisab.',
              'Pendapatan kasar tahunan ditaksir pada 2.5% apabila mencapai nisab.',
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<IncomeCalculationMethod>(
              groupValue: _incomeMethod,
              children: {
                IncomeCalculationMethod.simple: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(lang.getText('Simple', 'Ringkas')),
                ),
                IncomeCalculationMethod.detailed: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(lang.getText('With reliefs', 'Dengan pelepasan')),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                setState(() => _incomeMethod = value);
                _calculate();
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              isDetailed
                  ? lang.getText(
                      'Deducts self/spouse/child reliefs and other allowable expenses before applying 2.5%, similar to MAIJ\'s calculator.',
                      'Menolak pelepasan diri/isteri/anak dan perbelanjaan dibenarkan lain sebelum mengenakan 2.5%, seperti kalkulator MAIJ.',
                    )
                  : lang.getText(
                      'No reliefs — just gross income x 2.5%, minus any zakat already deducted at source.',
                      'Tiada pelepasan — hanya pendapatan kasar x 2.5%, ditolak zakat yang telah dipotong di sumber.',
                    ),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
          _moneyField(
            label: lang.getText('Gross monthly salary', 'Gaji kasar bulanan'),
            controller: _monthlySalaryController,
          ),
          _moneyField(
            label: lang.getText(
              'Other income this year',
              'Pendapatan lain tahun ini',
            ),
            controller: _otherAnnualIncomeController,
          ),
          _moneyField(
            label: lang.getText(
              'Zakat already deducted (payroll)',
              'Zakat telah dipotong (gaji)',
            ),
            controller: _zakatDeductedController,
          ),
          if (isDetailed) ...[
            const Divider(height: 28),
            Text(
              lang.getText('Reliefs (pelepasan)', 'Pelepasan'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _moneyField(
              label: lang.getText('Self relief', 'Pelepasan diri'),
              controller: _selfReliefController,
            ),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: lang.getText('No. of spouses', 'Bil. isteri'),
                    controller: _numberOfSpousesController,
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _moneyField(
                    label: lang.getText('Relief per spouse', 'Pelepasan seorang isteri'),
                    controller: _spouseReliefController,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: lang.getText('No. of children', 'Bil. anak'),
                    controller: _numberOfChildrenController,
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _moneyField(
                    label: lang.getText('Relief per child', 'Pelepasan seorang anak'),
                    controller: _childReliefController,
                  ),
                ),
              ],
            ),
            _moneyField(
              label: lang.getText('Parent support', 'Nafkah ibu bapa'),
              controller: _parentSupportController,
            ),
            _moneyField(
              label: lang.getText('Education expenses', 'Perbelanjaan pendidikan'),
              controller: _educationController,
            ),
            _moneyField(
              label: lang.getText('Medical expenses', 'Perbelanjaan perubatan'),
              controller: _medicalController,
            ),
            _moneyField(
              label: lang.getText('Tabung Haji savings', 'Simpanan Tabung Haji'),
              controller: _tabungHajiController,
            ),
            _moneyField(
              label: lang.getText('KWSP/EPF contribution', 'Caruman KWSP'),
              controller: _kwspController,
            ),
          ],
        ],
      ),
    );
  }

  Widget _savingsForm(LanguageProvider lang) {
    return AppSurface(
      key: const ValueKey('savings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeading(
            lang.getText('Savings held for a haul', 'Simpanan cukup haul'),
            lang.getText(
              'Enter the lowest balance held during the lunar year for each account.',
              'Masukkan baki terendah yang dipegang sepanjang tahun hijrah bagi setiap akaun.',
            ),
          ),
          for (var index = 0; index < _savings.length; index++) ...[
            _entryHeader(
              lang.getText('Account ${index + 1}', 'Akaun ${index + 1}'),
              canDelete: _savings.length > 1,
              onDelete: () {
                _savings.removeAt(index).dispose();
                _calculate();
              },
            ),
            TextField(
              controller: _savings[index].nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: lang.getText('Account name', 'Nama akaun'),
                prefixIcon: const Icon(CupertinoIcons.building_2_fill),
              ),
            ),
            const SizedBox(height: 12),
            _moneyField(
              label: lang.getText(
                'Lowest annual balance',
                'Baki terendah tahunan',
              ),
              controller: _savings[index].balanceController,
            ),
            if (index != _savings.length - 1) const Divider(height: 28),
          ],
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() => _savings.add(_SavingsEntry())),
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: Text(lang.getText('Add account', 'Tambah akaun')),
          ),
        ],
      ),
    );
  }

  Widget _goldForm(LanguageProvider lang) {
    return AppSurface(
      key: const ValueKey('gold'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeading(
            lang.getText('Gold holdings', 'Pegangan emas'),
            lang.getText(
              'State fatwa dictates if zakat applies to the full weight or only excess.',
              'Fatwa negeri menetapkan sama ada zakat dikenakan pada berat penuh atau lebihan sahaja.',
            ),
          ),
          for (var index = 0; index < _goldItems.length; index++) ...[
            _entryHeader(
              lang.getText('Gold item ${index + 1}', 'Item emas ${index + 1}'),
              canDelete: _goldItems.length > 1,
              onDelete: () {
                _goldItems.removeAt(index).dispose();
                _calculate();
              },
            ),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _goldItems[index].isWorn,
                children: {
                  false: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(lang.getText('Stored', 'Disimpan')),
                  ),
                  true: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(lang.getText('Worn', 'Dipakai')),
                  ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  _goldItems[index].isWorn = value;
                  _calculate();
                },
              ),
            ),
            const SizedBox(height: 12),
            _numberField(
              label: lang.getText('Weight', 'Berat'),
              controller: _goldItems[index].weightController,
              suffix: 'g',
            ),
            if (index != _goldItems.length - 1) const Divider(height: 28),
          ],
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() => _goldItems.add(_GoldEntry())),
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: Text(lang.getText('Add gold item', 'Tambah item emas')),
          ),
        ],
      ),
    );
  }

  Widget _silverForm(LanguageProvider lang) {
    return AppSurface(
      key: const ValueKey('silver'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeading(
            lang.getText('Silver holdings', 'Pegangan perak'),
            lang.getText(
              'Zakat applies once total silver reaches 595g, on the full weight.',
              'Zakat dikenakan apabila jumlah perak mencapai 595g, ke atas berat penuh.',
            ),
          ),
          for (var index = 0; index < _silverItems.length; index++) ...[
            _entryHeader(
              lang.getText('Silver item ${index + 1}', 'Item perak ${index + 1}'),
              canDelete: _silverItems.length > 1,
              onDelete: () {
                _silverItems.removeAt(index).dispose();
                _calculate();
              },
            ),
            _numberField(
              label: lang.getText('Weight', 'Berat'),
              controller: _silverItems[index].weightController,
              suffix: 'g',
            ),
            if (index != _silverItems.length - 1) const Divider(height: 28),
          ],
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() => _silverItems.add(_SilverEntry())),
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: Text(lang.getText('Add silver item', 'Tambah item perak')),
          ),
        ],
      ),
    );
  }

  Widget _formHeading(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _entryHeader(
    String title, {
    required bool canDelete,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (canDelete)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: onDelete,
              child: const Icon(
                CupertinoIcons.minus_circle,
                color: AppTheme.danger,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _calculate(),
      decoration: InputDecoration(labelText: label, prefixText: 'RM '),
    ),
  );

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _calculate(),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    ),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.income,
    required this.savings,
    required this.gold,
    required this.silver,
    required this.lang,
  });

  final double total;
  final double income;
  final double savings;
  final double gold;
  final double silver;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppTheme.primaryGreenDark,
      borderColor: AppTheme.primaryGreenDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('ESTIMATED TOTAL', 'JUMLAH ANGGARAN'),
            style: TextStyle(
              color: AppTheme.textOnPrimary.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'RM ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.textOnPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _breakdown(lang.getText('Income', 'Pendapatan'), income),
              _breakdown(lang.getText('Savings', 'Simpanan'), savings),
              _breakdown(lang.getText('Gold', 'Emas'), gold),
              _breakdown(lang.getText('Silver', 'Perak'), silver),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdown(String label, double value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textOnPrimary.withValues(alpha: 0.65),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'RM ${value.toStringAsFixed(2)}',
          maxLines: 1,
          style: const TextStyle(
            color: AppTheme.textOnPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SavingsEntry {
  _SavingsEntry({String? named})
    : nameController = TextEditingController(text: named ?? '');

  final TextEditingController nameController;
  final TextEditingController balanceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    balanceController.dispose();
  }
}

class _GoldEntry {
  final TextEditingController weightController = TextEditingController();
  bool isWorn = false;

  void dispose() => weightController.dispose();
}

class _SilverEntry {
  final TextEditingController weightController = TextEditingController();

  void dispose() => weightController.dispose();
}