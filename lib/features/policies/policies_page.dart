import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';

import '../../core/data/repo.dart';
import '../../core/utils/text_utils.dart';

class PoliciesPage extends StatefulWidget {
  const PoliciesPage({super.key});
  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> policies = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final c = await repo.list('customers');
    final p = await repo.policies();
    if (mounted)
      setState(() {
        customers = c;
        policies = p;
      });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final k = search.text.trim().toLowerCase();
    final filtered = customers
        .where((c) => k.isEmpty || textOf(c['name']).toLowerCase().contains(k))
        .toList();
    return Scaffold(
        appBar: AppBar(title: const Text('保單管理')),
        body: Column(children: [
          Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                  color: navy,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(34))),
              child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      hintText: '搜尋客戶姓名',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none)))),
          Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('尚無成交客戶'))
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final id = c['id'].toString();
                            final own = policies
                                .where(
                                    (e) => e['customer_id']?.toString() == id)
                                .length;
                            return Card(
                                child: ListTile(
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  CustomerPoliciesPage(
                                                      customer: c)));
                                      await load();
                                    },
                                    leading: const CircleAvatar(
                                        child:
                                            Icon(Icons.folder_copy_outlined)),
                                    title: Text(textOf(c['name']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    subtitle: Text('共 $own 張保單'),
                                    trailing: const Icon(Icons.chevron_right)));
                          }))),
        ]));
  }
}

class CustomerPoliciesPage extends StatefulWidget {
  const CustomerPoliciesPage({super.key, required this.customer});
  final Map<String, dynamic> customer;
  @override
  State<CustomerPoliciesPage> createState() => _CustomerPoliciesPageState();
}

class _CustomerPoliciesPageState extends State<CustomerPoliciesPage> {
  final repo = Repo();
  List<Map<String, dynamic>> rows = [];
  static const insurers = <String>[
    '臺銀人壽',
    '台灣人壽',
    '保誠人壽',
    '國泰人壽',
    '凱基人壽',
    '南山人壽',
    '新光人壽',
    '富邦人壽',
    '三商美邦人壽',
    '遠雄人壽',
    '宏泰人壽',
    '安聯人壽',
    '中華郵政',
    '全球人壽',
    '元大人壽',
    '第一金人壽',
    '合作金庫人壽',
    '安達國際人壽',
    '友邦人壽',
    '法國巴黎人壽',
    '臺灣產物保險',
    '兆豐產物保險',
    '富邦產物保險',
    '和泰產物保險',
    '泰安產物保險',
    '明台產物保險',
    '南山產物保險',
    '第一產物保險',
    '旺旺友聯產物保險',
    '新光產物保險',
    '華南產物保險',
    '國泰產物保險',
    '新安東京海上產物保險',
    '中國信託產物保險',
    '美國國際產物保險',
    '美商安達產物保險',
    '法國巴黎產物保險'
  ];
  String get customerId => widget.customer['id'].toString();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all = await repo.policies();
    if (mounted)
      setState(() => rows = all
          .where((e) => e['customer_id']?.toString() == customerId)
          .toList());
  }

  String premiumLabel(String f) => f == '半年繳'
      ? '半年繳保費'
      : f == '季繳'
          ? '季繳保費'
          : f == '月繳'
              ? '月繳保費'
              : '年繳保費';
  double annualized(double a, String f) => f == '半年繳'
      ? a * 2
      : f == '季繳'
          ? a * 4
          : f == '月繳'
              ? a * 12
              : a;

  Future<void> edit([Map<String, dynamic>? row]) async {
    final product = TextEditingController(text: textOf(row?['product_name']));
    String? insurer =
        textOf(row?['insurer']).isEmpty ? null : textOf(row?['insurer']);
    String frequency = textOf(row?['payment_frequency']).isNotEmpty
        ? textOf(row?['payment_frequency'])
        : (textOf(row?['payment_method']).isNotEmpty
            ? textOf(row?['payment_method'])
            : '年繳');

    String policyStatus = textOf(row?['policy_status']).isNotEmpty
        ? textOf(row?['policy_status'])
        : '有效';
    final premium = TextEditingController(
        text: textOf(row?['premium_amount']).isNotEmpty
            ? textOf(row?['premium_amount'])
            : textOf(row?['annual_premium']));
    final coverage =
        TextEditingController(text: textOf(row?['coverage_amount']));
    final effective =
        TextEditingController(text: textOf(row?['effective_date']));
    final maturity = TextEditingController(text: textOf(row?['maturity_date']));
    final notes = TextEditingController(text: textOf(row?['notes']));
    bool ridersContinue = row?['riders_continue_after_maturity'] == true;

    final existingRiders = row == null
        ? <Map<String, dynamic>>[]
        : await repo.policyRiders(row['id'].toString());
    final riderForms = <Map<String, dynamic>>[];
    for (final r in existingRiders) {
      riderForms.add({
        'name': TextEditingController(text: textOf(r['name'])),
        'coverage': TextEditingController(text: textOf(r['coverage_amount'])),
        'frequency': textOf(r['payment_frequency']).isEmpty
            ? '年繳'
            : textOf(r['payment_frequency']),
        'premium': TextEditingController(text: textOf(r['premium_amount'])),
        'paymentTerm': TextEditingController(text: textOf(r['payment_term'])),
        'maturity': TextEditingController(text: textOf(r['maturity_date'])),
        'notes': TextEditingController(text: textOf(r['notes'])),
      });
    }

    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheet) => Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                child: SingleChildScrollView(
                    child: Column(children: [
                  if (row == null)
                    addModalHeader(
                      context,
                      '新增保單｜${textOf(widget.customer['name'])}',
                      () =>
                          [
                            product.text,
                            premium.text,
                            coverage.text,
                            effective.text,
                            maturity.text,
                            notes.text
                          ].any((e) => e.trim().isNotEmpty) ||
                          riderForms.isNotEmpty,
                    )
                  else
                    Text('編輯保單｜${textOf(widget.customer['name'])}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  field(product, '主約 / 商品名稱 *'),
                  DropdownButtonFormField<String>(
                      initialValue: insurer,
                      hint: const Text('請選擇保險公司'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: '保險公司', border: OutlineInputBorder()),
                      items: insurers
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setSheet(() => insurer = v)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: const InputDecoration(
                          labelText: '主約繳費方式', border: OutlineInputBorder()),
                      items: const ['年繳', '半年繳', '季繳', '月繳', '躉繳']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => frequency = v);
                      }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: policyStatus,
                    decoration: const InputDecoration(
                      labelText: '保單狀態',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['有效', '失效', '解約', '滿期']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setSheet(() => policyStatus = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  field(premium, premiumLabel(frequency),
                      keyboardType: TextInputType.number),
                  field(coverage, '主約保額', keyboardType: TextInputType.number),
                  field(effective, '生效日（YYYY-MM-DD）'),
                  field(maturity, '主約滿期日（YYYY-MM-DD）'),
                  SwitchListTile(
                    value: ridersContinue,
                    onChanged: (v) => setSheet(() => ridersContinue = v),
                    title: const Text('主約滿期後，仍有附約需要繳費'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  field(notes, '保單備註', maxLines: 3),
                  const Divider(height: 30),
                  Row(children: [
                    const Expanded(
                        child: Text('附約',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900))),
                    FilledButton.icon(
                        onPressed: () => setSheet(() => riderForms.add({
                              'name': TextEditingController(),
                              'coverage': TextEditingController(),
                              'frequency': '年繳',
                              'premium': TextEditingController(),
                              'paymentTerm': TextEditingController(),
                              'maturity': TextEditingController(),
                              'notes': TextEditingController(),
                            })),
                        icon: const Icon(Icons.add),
                        label: const Text('新增附約')),
                  ]),
                  const SizedBox(height: 8),
                  if (riderForms.isEmpty)
                    const Align(
                        alignment: Alignment.centerLeft, child: Text('目前沒有附約')),
                  ...List.generate(riderForms.length, (i) {
                    final r = riderForms[i];
                    final rf = r['frequency'] as String;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: Text('附約 ${i + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900))),
                              IconButton(
                                  onPressed: () =>
                                      setSheet(() => riderForms.removeAt(i)),
                                  icon: const Icon(Icons.delete_outline)),
                            ]),
                            field(r['name'] as TextEditingController, '附約名稱 *'),
                            field(
                                r['coverage'] as TextEditingController, '附約保額',
                                keyboardType: TextInputType.number),
                            DropdownButtonFormField<String>(
                                initialValue: rf,
                                decoration: const InputDecoration(
                                    labelText: '附約繳費方式',
                                    border: OutlineInputBorder()),
                                items: const ['年繳', '半年繳', '季繳', '月繳', '躉繳']
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null)
                                    setSheet(() => r['frequency'] = v);
                                }),
                            const SizedBox(height: 12),
                            field(r['premium'] as TextEditingController,
                                premiumLabel(r['frequency'] as String),
                                keyboardType: TextInputType.number),
                            field(r['paymentTerm'] as TextEditingController,
                                '附約繳費年期 / 說明'),
                            field(r['maturity'] as TextEditingController,
                                '附約滿期日（YYYY-MM-DD）'),
                            field(r['notes'] as TextEditingController, '附約備註',
                                maxLines: 2),
                          ])),
                    );
                  }),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('儲存保單')),
                ])))));

    if (saved != true || product.text.trim().isEmpty || insurer == null) return;
    final amount = double.tryParse(premium.text) ?? 0;
    final values = {
      'customer_id': customerId,
      'product_name': product.text.trim(),
      'insurer': insurer,
      'payment_frequency': frequency,
      'payment_method': frequency,
      'policy_status': policyStatus,
      'premium_amount': amount,
      'annual_premium': annualized(amount, frequency),
      'coverage_amount': double.tryParse(coverage.text) ?? 0,
      'effective_date': blank(effective.text),
      'maturity_date': blank(maturity.text),
      'riders_continue_after_maturity': ridersContinue,
      'notes': blank(notes.text)
    };
    String policyId;
    if (row == null) {
      final created = await repo.insertReturning('policies', values);
      policyId = created['id'].toString();
    } else {
      policyId = row['id'].toString();
      await repo.update('policies', policyId, values);
    }

    final riders = <Map<String, dynamic>>[];
    for (final r in riderForms) {
      final name = (r['name'] as TextEditingController).text.trim();
      if (name.isEmpty) continue;
      final rf = r['frequency'] as String;
      final ra =
          double.tryParse((r['premium'] as TextEditingController).text) ?? 0;
      riders.add({
        'name': name,
        'coverage_amount':
            double.tryParse((r['coverage'] as TextEditingController).text) ?? 0,
        'payment_frequency': rf,
        'premium_amount': ra,
        'annual_premium': annualized(ra, rf),
        'payment_term': blank((r['paymentTerm'] as TextEditingController).text),
        'maturity_date': blank((r['maturity'] as TextEditingController).text),
        'notes': blank((r['notes'] as TextEditingController).text),
      });
    }
    await repo.replacePolicyRiders(policyId, riders);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern('zh_TW');
    return Scaffold(
        appBar: AppBar(title: Text('${textOf(widget.customer['name'])}｜保單')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('新增保單')),
        body: rows.isEmpty
            ? const Center(child: Text('這位客戶尚無保單'))
            : RefreshIndicator(
                onRefresh: load,
                child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final f = textOf(row['payment_frequency']).isNotEmpty
                          ? textOf(row['payment_frequency'])
                          : textOf(row['payment_method']);
                      final a = double.tryParse(
                              textOf(row['premium_amount']).isNotEmpty
                                  ? textOf(row['premium_amount'])
                                  : textOf(row['annual_premium'])) ??
                          0;
                      return FutureBuilder<List<Map<String, dynamic>>>(
                          future: repo.policyRiders(row['id'].toString()),
                          builder: (context, snap) {
                            final riderCount = snap.data?.length ?? 0;
                            return Card(
                                child: ListTile(
                                    onTap: () => edit(row),
                                    leading: const CircleAvatar(
                                        child:
                                            Icon(Icons.description_outlined)),
                                    title: Text(textOf(row['product_name']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    subtitle: Text([
                                      textOf(row['insurer']),
                                      f,
                                      '${premiumLabel(f)} ${currency.format(a)} 元',
                                      textOf(row['maturity_date']).isEmpty
                                          ? ''
                                          : '主約滿期 ${textOf(row['maturity_date'])}',
                                      '附約 $riderCount 個${row['riders_continue_after_maturity'] == true ? '・主約滿期後仍需繳費' : ''}'
                                    ].where((e) => e.isNotEmpty).join('\n')),
                                    trailing: PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'edit')
                                            await edit(row);
                                          else
                                            await confirmDelete(context,
                                                () async {
                                              await repo.remove('policies',
                                                  row['id'].toString());
                                              await load();
                                            });
                                        },
                                        itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('編輯主約 / 附約')),
                                              PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('刪除'))
                                            ])));
                          });
                    })));
  }
}
