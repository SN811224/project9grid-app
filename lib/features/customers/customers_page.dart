import 'package:flutter/material.dart';

import '../../core/data/repo.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../policies/policies_page.dart';
import '../referrals/referral_tree_page.dart';
import '../../core/utils/follow_up_utils.dart';
import '../../core/utils/customer_utils.dart';
import 'package:intl/intl.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> customerLogs = [];
  bool loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final next = await repo.list('customers');
    final logs = await repo.list('follow_logs');
    if (!mounted) return;
    setState(() {
      rows = next;
      customerLogs = logs;
      loading = false;
    });
  }

  DateTime? lastCustomerProgress(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final dates = customerLogs
        .where((e) => e['customer_id']?.toString() == id)
        .map((e) => parseAnyDate(e['contacted_at'] ?? e['created_at']))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isNotEmpty) return dates.first;
    return parseAnyDate(row['closed_date'] ?? row['created_at']);
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: textOf(row?['name']));
    final phone = TextEditingController(text: textOf(row?['phone']));
    final lineId = TextEditingController(text: textOf(row?['line_id']));
    final birthday = TextEditingController(text: textOf(row?['birthday']));
    final occupation = TextEditingController(text: textOf(row?['occupation']));
    final company = TextEditingController(text: textOf(row?['company']));
    final family = TextEditingController(text: textOf(row?['family_status']));
    final premium = TextEditingController(text: textOf(row?['annual_premium']));
    final notes = TextEditingController(text: textOf(row?['notes']));
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (row == null)
                  addModalHeader(
                    context,
                    '新增成交客戶',
                    () => [
                      name.text,
                      phone.text,
                      lineId.text,
                      birthday.text,
                      occupation.text,
                      company.text,
                      family.text,
                      premium.text,
                      notes.text,
                    ].any((e) => e.trim().isNotEmpty),
                  )
                else
                  const Text(
                    '編輯成交客戶',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 18),
                field(name, '姓名 *'),
                field(phone, '手機'),
                field(lineId, 'LINE ID'),
                field(birthday, '生日（民國YYY-MM-DD）'),
                field(occupation, '職業'),
                field(company, '公司'),
                field(family, '家庭狀況'),
                field(
                  premium,
                  '年繳保費',
                  keyboardType: TextInputType.number,
                ),
                field(notes, '備註', maxLines: 3),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty) {
                      await showFormWarning(context, '姓名為必填欄位。');
                      return;
                    }
                    if (!isValidPhoneInput(phone.text)) {
                      await showFormWarning(context, '手機格式不正確，請重新輸入。');
                      return;
                    }
                    final birthdayCheck = normalizeBirthdayInput(birthday.text);
                    if (birthdayCheck == '__INVALID__') {
                      await showFormWarning(
                        context,
                        '生日格式不正確。請輸入民國年，例如 81-12-24；也可輸入西元 1981-12-24。',
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('儲存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (name.text.trim().isEmpty) {
      await showFormWarning(context, '姓名為必填欄位。');
      return;
    }
    if (!isValidPhoneInput(phone.text)) {
      await showFormWarning(context, '手機格式不正確，請重新輸入。');
      return;
    }
    final normalizedBirthday = normalizeBirthdayInput(birthday.text);
    if (normalizedBirthday == '__INVALID__') {
      await showFormWarning(
        context,
        '生日格式不正確。請輸入民國年，例如 81-12-24 或 081-12-24；也可輸入西元 1981-12-24。',
      );
      return;
    }

    final values = {
      'name': name.text.trim(),
      'phone': blank(phone.text),
      'line_id': blank(lineId.text),
      'birthday': normalizedBirthday,
      'occupation': blank(occupation.text),
      'company': blank(company.text),
      'family_status': blank(family.text),
      'annual_premium': double.tryParse(premium.text) ?? 0,
      'notes': blank(notes.text),
      'closed_date': row?['closed_date'] ??
          DateTime.now().toIso8601String().split('T').first,
    };

    if (row == null) {
      await repo.insert('customers', values);
    } else {
      await repo.update('customers', row['id'].toString(), values);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final keyword = search.text.trim().toLowerCase();
    final filtered = rows.where((row) {
      final haystack = [
        row['name'],
        row['phone'],
        row['occupation'],
        row['company'],
      ].whereType<Object>().join(' ').toLowerCase();
      return keyword.isEmpty || haystack.contains(keyword);
    }).toList()
      ..sort((a, b) {
        // 第一順位：成交日期由新到舊
        final closedA =
            parseAnyDate(a['closed_date'] ?? a['created_at']) ?? DateTime(1970);
        final closedB =
            parseAnyDate(b['closed_date'] ?? b['created_at']) ?? DateTime(1970);
        final closedCompare = closedB.compareTo(closedA);
        if (closedCompare != 0) return closedCompare;

        // 第二順位：同一天成交，再沿用原本燈號／追蹤天數規則

        final lightA = customerFollowUpLightFor(lastCustomerProgress(a));
        final lightB = customerFollowUpLightFor(lastCustomerProgress(b));
        final byLight =
            followUpPriority(lightA).compareTo(followUpPriority(lightB));
        if (byLight != 0) return byLight;
        final da =
            lastCustomerProgress(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            lastCustomerProgress(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('成交客戶')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
            ),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜尋姓名、手機、職業或公司',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('尚無成交客戶'))
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CustomerDetailPage(customer: row),
                                    ),
                                  );
                                  await load();
                                },
                                title: Row(
                                  children: [
                                    followUpDot(
                                      customerFollowUpLightFor(
                                        lastCustomerProgress(row),
                                      ),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        nameWithRocBirthday(
                                          row['name'],
                                          row['birthday'],
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(textOf(row['phone'])),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await edit(row);
                                    } else {
                                      await confirmDelete(
                                        context,
                                        () async {
                                          await repo.remove(
                                            'customers',
                                            row['id'].toString(),
                                          );
                                          await load();
                                        },
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('編輯'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('刪除'),
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

class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key, required this.customer});

  final Map<String, dynamic> customer;

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final repo = Repo();
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> policies = [];
  List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> engagementHistory = [];

  String get customerId => widget.customer['id'].toString();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final allContacts = await repo.list('contacts');
    final allPolicies = await repo.policies();
    final allLogs = await repo.followLogs(customerId);
    final sourceProspectId = textOf(widget.customer['source_prospect_id']);
    final oldEngagement = sourceProspectId.isEmpty
        ? <Map<String, dynamic>>[]
        : await repo.engagementLogs(sourceProspectId);
    if (!mounted) return;
    setState(() {
      contacts = allContacts
          .where((e) => e['customer_id']?.toString() == customerId)
          .toList();
      policies = allPolicies
          .where((e) => e['customer_id']?.toString() == customerId)
          .toList();
      logs = allLogs;
      engagementHistory = oldEngagement;
    });
  }

  DateTime? get customerLastContact {
    final dates = logs
        .map((e) => parseAnyDate(e['contacted_at'] ?? e['created_at']))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isNotEmpty) return dates.first;
    return parseAnyDate(
      widget.customer['closed_date'] ?? widget.customer['created_at'],
    );
  }

  Widget customerLightCard() {
    final light = customerFollowUpLightFor(customerLastContact);
    final dateText = customerLastContact == null
        ? '尚無聯絡紀錄'
        : DateFormat('yyyy-MM-dd').format(customerLastContact!);
    return Card(
      child: ListTile(
        leading: followUpDot(light, size: 16),
        title: Text(
          customerFollowUpLabel(light),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: followUpColor(light),
          ),
        ),
        subtitle: Text('最近聯絡：$dateText'),
      ),
    );
  }

  Future<void> addFollowLog() async {
    final contactedOn = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final summary = TextEditingController();
    String channel = '電話';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                addModalHeader(
                  context,
                  '新增聯絡紀錄',
                  () => summary.text.trim().isNotEmpty || channel != '電話',
                ),
                const SizedBox(height: 16),
                field(contactedOn, '聯絡日期（YYYY-MM-DD）'),
                DropdownButtonFormField<String>(
                  initialValue: channel,
                  decoration: const InputDecoration(
                    labelText: '聯絡方式',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '電話', child: Text('電話')),
                    DropdownMenuItem(value: 'LINE', child: Text('LINE')),
                    DropdownMenuItem(value: '面談', child: Text('面談')),
                    DropdownMenuItem(value: 'Email', child: Text('Email')),
                    DropdownMenuItem(value: '其他', child: Text('其他')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => channel = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                field(summary, '聯絡內容 *', maxLines: 5),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('儲存聯絡紀錄'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (summary.text.trim().isEmpty) {
      if (mounted) snack(context, '請輸入聯絡內容');
      return;
    }

    final date = parseFormDate(contactedOn.text);
    if (date == null) {
      if (mounted)
        snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
      return;
    }

    try {
      await repo.insert('follow_logs', {
        'customer_id': customerId,
        'channel': channel,
        'summary': summary.text.trim(),
        'contacted_at': DateTime(
          date.year,
          date.month,
          date.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
          DateTime.now().millisecond,
        ).toIso8601String(),
      });
      await load();
      if (mounted) snack(context, '聯絡紀錄已新增');
    } catch (e) {
      if (mounted) snack(context, '聯絡紀錄儲存失敗：$e');
    }
  }

  Future<void> editFollowLog(Map<String, dynamic> row) async {
    final rawDate = textOf(row['contacted_at']);
    final parsed = DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();
    final contactedOn = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(parsed),
    );
    final summary = TextEditingController(text: textOf(row['summary']));
    String channel =
        textOf(row['channel']).isEmpty ? '電話' : textOf(row['channel']);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '修改聯絡紀錄',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                field(contactedOn, '聯絡日期（YYYY-MM-DD）'),
                DropdownButtonFormField<String>(
                  initialValue: channel,
                  decoration: const InputDecoration(
                    labelText: '聯絡方式',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '電話', child: Text('電話')),
                    DropdownMenuItem(value: 'LINE', child: Text('LINE')),
                    DropdownMenuItem(value: '面談', child: Text('面談')),
                    DropdownMenuItem(value: 'Email', child: Text('Email')),
                    DropdownMenuItem(value: '其他', child: Text('其他')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => channel = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                field(summary, '聯絡內容 *', maxLines: 5),
                FilledButton.icon(
                  onPressed: () {
                    if (summary.text.trim().isEmpty) {
                      snack(context, '請輸入聯絡內容');
                      return;
                    }
                    if (parseFormDate(contactedOn.text) == null) {
                      snack(context,
                          '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('儲存修改'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (summary.text.trim().isEmpty) {
      if (mounted) snack(context, '請輸入聯絡內容');
      return;
    }
    final date = parseFormDate(contactedOn.text);
    if (date == null) {
      if (mounted)
        snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
      return;
    }

    try {
      await repo.update('follow_logs', row['id'].toString(), {
        'channel': channel,
        'summary': summary.text.trim(),
        'contacted_at':
            DateTime(date.year, date.month, date.day).toIso8601String(),
      });
      await load();
      if (mounted) snack(context, '聯絡紀錄已修改');
    } catch (e) {
      if (mounted) snack(context, '聯絡紀錄修改失敗：$e');
    }
  }

  Future<void> copyToRecruitment() async {
    final c = widget.customer;
    try {
      final existing = (await repo.list('recruitments'))
          .where((e) => textOf(e['source_customer_id']) == customerId)
          .toList();
      if (existing.isNotEmpty) {
        if (mounted) snack(context, '這位客戶已經在增員名單中');
        return;
      }
      await repo.insert('recruitments', {
        'name': textOf(c['name']),
        'phone': c['phone'],
        'line_id': c['line_id'],
        'birthday': c['birthday'],
        'occupation': c['occupation'],
        'company': c['company'],
        'family_status': c['family_status'],
        'notes': c['notes'],
        'status': '增員中',
        'source_customer_id': customerId,
        'source_type': '成交客戶',
        'referred_by_name': textOf(c['name']),
      });
      if (mounted) snack(context, '已複製到增員名單，原客戶資料保留');
    } catch (e) {
      if (mounted) snack(context, '複製到增員失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(textOf(c['name']))),
      bottomNavigationBar: mainNavigationBar(context, 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addFollowLog,
        icon: const Icon(Icons.add_comment),
        label: const Text('聯絡紀錄'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    infoRow('手機', textOf(c['phone'])),
                    infoRow('LINE', textOf(c['line_id'])),
                    infoRow('生日', formatRocBirthday(c['birthday'])),
                    infoRow('職業', textOf(c['occupation'])),
                    infoRow('公司', textOf(c['company'])),
                    infoRow('家庭', textOf(c['family_status'])),
                    infoRow('年繳保費', textOf(c['annual_premium'])),
                    infoRow('備註', textOf(c['notes'])),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: const Text('推薦樹狀圖',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReferralTreePage(rootCustomer: c),
                  ),
                ),
              ),
            ),
            sectionTitle('九宮格人脈 ${contacts.length} 人'),
            ...contacts.take(5).map(
                  (e) => Card(
                    child: ListTile(
                      title: Text(textOf(e['name'])),
                      subtitle: Text(
                        '${textOf(e['category'])}・${textOf(e['status'])}',
                      ),
                    ),
                  ),
                ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerPoliciesPage(customer: c),
                        ),
                      );
                      await load();
                    },
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('保單管理'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: copyToRecruitment,
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('成交轉增員'),
                  ),
                ),
              ],
            ),
            if (engagementHistory.isNotEmpty) ...[
              sectionTitle('成交前經營紀錄 ${engagementHistory.length} 筆'),
              ...engagementHistory.map(
                (e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.handshake_outlined),
                    title: Text(textOf(e['content'])),
                    subtitle: Text([
                      formatDateOnly(e['engaged_on'] ?? e['engaged_at']),
                      textOf(e['status_note']),
                    ].where((x) => x.isNotEmpty).join('\n')),
                  ),
                ),
              ),
            ],
            sectionTitle('保單 ${policies.length} 張'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder_copy_outlined),
                title: const Text('查看／新增／修改全部保單'),
                subtitle: Text('目前共 ${policies.length} 張保單'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerPoliciesPage(customer: c),
                    ),
                  );
                  await load();
                },
              ),
            ),
            ...policies.take(5).map(
                  (e) => SizedBox(
                    height: 92,
                    child: Card(
                      child: ListTile(
                        title: Text(
                          textOf(e['product_name']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${textOf(e['insurer'])} · ${textOf(e['payment_frequency'] ?? e['payment_method'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            sectionTitle('聯絡紀錄'),
            if (logs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('尚無聯絡紀錄'),
                ),
              ),
            ...logs.map(
              (e) => SizedBox(
                height: 92,
                child: Card(
                  child: ListTile(
                    onTap: () => editFollowLog(e),
                    leading: const Icon(Icons.history),
                    title: Text(
                      textOf(e['summary']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${textOf(e['channel'])} · ${formatDateOnly(e['contacted_at'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await editFollowLog(e);
                        } else if (value == 'delete') {
                          await confirmDelete(context, () async {
                            await repo.remove(
                              'follow_logs',
                              e['id'].toString(),
                            );
                            await load();
                          });
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('修改')),
                        PopupMenuItem(value: 'delete', child: Text('刪除')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
