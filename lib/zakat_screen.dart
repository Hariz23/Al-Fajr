import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _nisabController = TextEditingController(text: '33996.00');
  final _goldPriceController = TextEditingController(text: '399.95');
  final _wornUrufController = TextEditingController(
    text: ZakatCalculator.wornGoldThresholdGrams.toStringAsFixed(0),
  );
  final _monthlySalaryController = TextEditingController();
  final _otherAnnualIncomeController = TextEditingController();
  final _zakatPaidController = TextEditingController();

  final List<_SavingsEntry> _savings = [_SavingsEntry(named: 'Account 1')];
  final List<_GoldEntry> _goldItems = [_GoldEntry()];

  int _section = 0;
  double _incomeZakat = 0;
  double _savingsZakat = 0;
  double _goldZakat = 0;

  double get _total => _incomeZakat + _savingsZakat + _goldZakat;
  double get _nisab => _parse(_nisabController.text);
  double get _goldPrice => _parse(_goldPriceController.text);
  double get _wornUruf => _parse(_wornUrufController.text);

  @override
  void dispose() {
    _nisabController.dispose();
    _goldPriceController.dispose();
    _wornUrufController.dispose();
    _monthlySalaryController.dispose();
    _otherAnnualIncomeController.dispose();
    _zakatPaidController.dispose();
    for (final entry in _savings) {
      entry.dispose();
    }
    for (final entry in _goldItems) {
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

  void _calculate() {
    var goldZakat = 0.0;
    for (final item in _goldItems) {
      goldZakat += ZakatCalculator.goldItem(
        weightGrams: _parse(item.weightController.text),
        pricePerGram: _goldPrice,
        isWorn: item.isWorn,
        wornUrufGrams: _wornUruf,
      );
    }

    setState(() {
      _incomeZakat = ZakatCalculator.income(
        monthlySalary: _parse(_monthlySalaryController.text),
        otherAnnualIncome: _parse(_otherAnnualIncomeController.text),
        alreadyPaid: _parse(_zakatPaidController.text),
        nisab: _nisab,
      );
      _savingsZakat = ZakatCalculator.savings(
        lowestAnnualBalances: _savings.map(
          (entry) => _parse(entry.balanceController.text),
        ),
        nisab: _nisab,
      );
      _goldZakat = goldZakat;
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
    _zakatPaidController.clear();
    for (final entry in _savings.skip(1)) {
      entry.dispose();
    }
    for (final item in _goldItems.skip(1)) {
      item.dispose();
    }
    _savings
      ..removeRange(1, _savings.length)
      ..first.balanceController.clear();
    _goldItems
      ..removeRange(1, _goldItems.length)
      ..first.weightController.clear();
    setState(() {
      _incomeZakat = 0;
      _savingsZakat = 0;
      _goldZakat = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('Zakat estimate', 'Anggaran zakat'),
      subtitle: lang.getText(
        'Wilayah Persekutuan reference method',
        'Kaedah rujukan Wilayah Persekutuan',
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
            lang: lang,
          ),
          const SizedBox(height: 16),
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
              _ => _goldForm(lang),
            },
          ),
          const SizedBox(height: 18),
          AppSurface(
            color: AppTheme.warmCream,
            borderColor: AppTheme.paleGold,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.info_circle_fill,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang.getText(
                      'This is an estimate, not an official assessment. Eligibility can depend on haul, had kifayah and your state authority. Verify before paying.',
                      'Ini ialah anggaran, bukan taksiran rasmi. Kelayakan boleh bergantung pada haul, had kifayah dan pihak berkuasa negeri anda. Sahkan sebelum membayar.',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

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
          _numberField(
            label: lang.getText('Worn gold uruf', 'Uruf emas dipakai'),
            controller: _wornUrufController,
            suffix: 'g',
          ),
          const SizedBox(height: 2),
          Text(
            lang.getText(
              'Stored gold: 85 g nisab, charged in full • worn gold: charged on the weight above the uruf • rate: 2.5%',
              'Emas simpan: nisab 85 g, dikenakan sepenuhnya • emas dipakai: dikenakan atas berat melebihi uruf • kadar: 2.5%',
            ),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://www.zakat.com.my/info-zakat/jenis-jenis-zakat/zakat-pendapatan/',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 17),
              label: Text(
                lang.getText('Official PPZ guidance', 'Panduan rasmi PPZ'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomeForm(LanguageProvider lang) {
    return AppSurface(
      key: const ValueKey('income'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeading(
            lang.getText('Annual income', 'Pendapatan tahunan'),
            lang.getText(
              'Gross yearly income is assessed at 2.5% once it reaches the selected nisab.',
              'Pendapatan kasar tahunan ditaksir pada 2.5% apabila mencapai nisab yang dipilih.',
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
              'Zakat already paid this year',
              'Zakat telah dibayar tahun ini',
            ),
            controller: _zakatPaidController,
          ),
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
              'Stored and worn gold use different Wilayah Persekutuan thresholds.',
              'Emas simpan dan dipakai menggunakan ambang Wilayah Persekutuan yang berbeza.',
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
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) => _calculate(),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.income,
    required this.savings,
    required this.gold,
    required this.lang,
  });

  final double total;
  final double income;
  final double savings;
  final double gold;
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
