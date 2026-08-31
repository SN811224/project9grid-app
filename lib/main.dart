import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vgmtonkdgikpfnlkskqm.supabase.co';
const supabaseKey = 'sb_publishable_vpgCkWsA2k69mh9Z2W__cg_Szbz4Iko';

const navy = Color(0xFF214D8D);
const bg = Color(0xFFF3F6FB);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF3F6FB),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                '推薦互動程式 發生畫面錯誤\n\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
  runApp(const Project9GridBootstrap());
}

class Project9GridBootstrap extends StatefulWidget {
  const Project9GridBootstrap({super.key});

  @override
  State<Project9GridBootstrap> createState() => _Project9GridBootstrapState();
}

class _Project9GridBootstrapState extends State<Project9GridBootstrap> {
  late final Future<void> _startup = _initialize();

  Future<void> _initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    ).timeout(const Duration(seconds: 15));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '推薦互動程式',
      theme: appTheme(),
      home: FutureBuilder<void>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('推薦互動程式 啟動中…'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return StartupErrorPage(error: snapshot.error);
          }

          return const AuthGate();
        },
      ),
    );
  }
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: navy),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({super.key, required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      '無法啟動 推薦互動程式',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Supabase 連線初始化沒有成功。請把下方訊息截圖給我。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      '$error',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        return Supabase.instance.client.auth.currentSession == null
            ? const LoginPage()
            : const ShellPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool registerMode = false;
  bool loading = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      toast('請輸入 Email，密碼至少 6 碼');
      return;
    }
    setState(() => loading = true);
    try {
      if (registerMode) {
        await Supabase.instance.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
        toast('註冊完成，請至信箱驗證後登入');
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      toast(e.message);
    } catch (e) {
      toast('發生錯誤：$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final value = email.text.trim();
    if (value.isEmpty) {
      toast('請先輸入 Email');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(value);
      toast('密碼重設信已寄出，請到信箱查看');
    } on AuthException catch (e) {
      toast(e.message);
    } catch (e) {
      toast('無法寄送重設信：$e');
    }
  }

  void toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 58),
                    const SizedBox(height: 16),
                    const Text(
                      '推薦互動程式',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密碼',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        child: Text(
                          loading
                              ? '處理中…'
                              : (registerMode ? '建立帳號' : '登入'),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => registerMode = !registerMode),
                      child: Text(
                        registerMode ? '已有帳號，改用登入' : '沒有帳號，建立帳號',
                      ),
                    ),
                    if (!registerMode)
                      TextButton(
                        onPressed: resetPassword,
                        child: const Text('忘記密碼'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Repo {
  SupabaseClient get client => Supabase.instance.client;

  String get uid {
    final value = client.auth.currentUser?.id;
    if (value == null) throw StateError('尚未登入');
    return value;
  }

  Future<List<Map<String, dynamic>>> list(String table) async {
    final rows = await client
        .from(table)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    await client.from(table).insert({'user_id': uid, ...values});
  }

  Future<void> update(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    await client
        .from(table)
        .update(values)
        .eq('id', id)
        .eq('user_id', uid);
  }

  Future<void> remove(String table, String id) async {
    await client.from(table).delete().eq('id', id).eq('user_id', uid);
  }

  Future<List<Map<String, dynamic>>> policies() async {
    final rows = await client
        .from('policies')
        .select('*, customers(name)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> followLogs(String customerId) async {
    final rows = await client
        .from('follow_logs')
        .select()
        .eq('user_id', uid)
        .eq('customer_id', customerId)
        .order('contacted_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, int>> counts() async {
    final customers = await list('customers');
    final contacts = await list('contacts');
    final todos = await list('todos');
    return {
      'customers': customers.length,
      'contacts': contacts.length,
      'todos': todos.where((e) => e['status'] != '已完成').length,
      'converted': contacts.where((e) => e['status'] == '已成交').length,
    };
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    CustomersPage(),
    GridPage(),
    TodosPage(),
    PoliciesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首頁'),
          NavigationDestination(icon: Icon(Icons.people), label: '客戶'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: '九宮格'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: '待辦'),
          NavigationDestination(icon: Icon(Icons.description), label: '保單'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  Map<String, int> counts = const {
    'customers': 0,
    'contacts': 0,
    'todos': 0,
    'converted': 0,
  };
  List<Map<String, dynamic>> birthdays = [];
  bool loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final newCounts = await repo.counts();
    final customers = await repo.list('customers');
    final now = DateTime.now();

    final upcoming = customers.where((row) {
      final raw = row['birthday']?.toString();
      final birthday = raw == null ? null : DateTime.tryParse(raw);
      if (birthday == null) return false;
      var next = DateTime(now.year, birthday.month, birthday.day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year + 1, birthday.month, birthday.day);
      }
      return next.difference(DateTime(now.year, now.month, now.day)).inDays <= 30;
    }).toList();

    if (!mounted) return;
    setState(() {
      counts = newCounts;
      birthdays = upcoming;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁戰情室'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ClassicHeader(
              kicker: '推薦互動程式',
              title: '首頁戰情室',
              subtitle: '成交客戶 → 轉介紹 → 新成交',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '整體概況',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      MetricCard(value: counts['customers']!, label: '成交客戶'),
                      MetricCard(value: counts['contacts']!, label: '總人脈'),
                      MetricCard(value: counts['todos']!, label: '待追蹤'),
                      MetricCard(value: counts['converted']!, label: '人脈成交'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              birthdays.isEmpty
                                  ? '30 天內沒有客戶生日'
                                  : '30 天內有 ${birthdays.length} 位客戶生日',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '九宮格平均完成度',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '—',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: loading ? null : 0,
                            minHeight: 11,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassicHeader extends StatelessWidget {
  const ClassicHeader({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: const TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF6E788D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    if (!mounted) return;
    setState(() {
      rows = next;
      loading = false;
    });
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
    int priority = int.tryParse(textOf(row?['priority'])) ?? 3;

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
                Text(
                  row == null ? '新增成交客戶' : '編輯成交客戶',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                field(name, '姓名 *'),
                field(phone, '手機'),
                field(lineId, 'LINE ID'),
                field(birthday, '生日（YYYY-MM-DD）'),
                field(occupation, '職業'),
                field(company, '公司'),
                field(family, '家庭狀況'),
                field(
                  premium,
                  '年繳保費',
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<int>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: '優先度',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} 星'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                field(notes, '備註', maxLines: 3),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('儲存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || name.text.trim().isEmpty) return;

    final values = {
      'name': name.text.trim(),
      'phone': blank(phone.text),
      'line_id': blank(lineId.text),
      'birthday': blank(birthday.text),
      'occupation': blank(occupation.text),
      'company': blank(company.text),
      'family_status': blank(family.text),
      'annual_premium': double.tryParse(premium.text) ?? 0,
      'priority': priority,
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
    }).toList();

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
              color: navy,
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
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE7EEF9),
                                  child: Text(
                                    textOf(row['name']).isEmpty
                                        ? '?'
                                        : textOf(row['name'])[0],
                                  ),
                                ),
                                title: Text(
                                  textOf(row['name']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    row['occupation'],
                                    row['company'],
                                    row['phone'],
                                  ]
                                      .whereType<Object>()
                                      .map((e) => e.toString())
                                      .where((e) => e.isNotEmpty)
                                      .join('・'),
                                ),
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
    if (!mounted) return;
    setState(() {
      contacts = allContacts
          .where((e) => e['customer_id']?.toString() == customerId)
          .toList();
      policies = allPolicies
          .where((e) => e['customer_id']?.toString() == customerId)
          .toList();
      logs = allLogs;
    });
  }

  Future<void> addFollowLog() async {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '新增聯絡紀錄',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
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
              field(summary, '內容 *', maxLines: 4),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && summary.text.trim().isNotEmpty) {
      await repo.insert('follow_logs', {
        'customer_id': customerId,
        'channel': channel,
        'summary': summary.text.trim(),
        'contacted_at': DateTime.now().toIso8601String(),
      });
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(textOf(c['name']))),
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
                    infoRow('生日', textOf(c['birthday'])),
                    infoRow('職業', textOf(c['occupation'])),
                    infoRow('公司', textOf(c['company'])),
                    infoRow('家庭', textOf(c['family_status'])),
                    infoRow('年繳保費', textOf(c['annual_premium'])),
                    infoRow('備註', textOf(c['notes'])),
                  ],
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
            sectionTitle('保單 ${policies.length} 張'),
            ...policies.take(5).map(
                  (e) => Card(
                    child: ListTile(
                      title: Text(textOf(e['product_name'])),
                      subtitle: Text(
                        '${textOf(e['policy_type'])}・${textOf(e['insurer'])}',
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
              (e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(textOf(e['summary'])),
                  subtitle: Text(
                    '${textOf(e['channel'])}・${formatDateTime(e['contacted_at'])}',
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

class GridPage extends StatefulWidget {
  const GridPage({super.key});

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage>
    with AutomaticKeepAliveClientMixin {
  static const categories = [
    '親戚',
    '同學',
    '鄰居',
    '同事',
    '前同事',
    '家人',
    '朋友',
    '社團',
  ];

  final repo = Repo();
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> contacts = [];
  String? selectedCustomerId;

  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? get selectedCustomer {
    if (selectedCustomerId == null) return null;
    for (final c in customers) {
      if (c['id'].toString() == selectedCustomerId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final c = await repo.list('customers');
    final p = await repo.list('contacts');
    if (!mounted) return;
    setState(() {
      customers = c;
      contacts = p;
      if (selectedCustomerId != null &&
          !customers.any((e) => e['id'].toString() == selectedCustomerId)) {
        selectedCustomerId = null;
      }
    });
  }

  int countFor(String category) {
    if (selectedCustomerId == null) return 0;
    return contacts.where((e) =>
      e['customer_id']?.toString() == selectedCustomerId &&
      e['category']?.toString() == category
    ).length;
  }

  Future<void> chooseCustomer() async {
    if (customers.isEmpty) {
      snack(context, '目前沒有成交客戶，請先到「客戶」新增');
      return;
    }
    final picked = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('選擇成交客戶',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('清除選擇'),
            onTap: () => Navigator.pop(context, ''),
          ),
          ...customers.map((c) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(textOf(c['name'])),
            subtitle: Text([
              textOf(c['occupation']),
              textOf(c['company'])
            ].where((e) => e.isNotEmpty).join('・')),
            trailing: selectedCustomerId == c['id'].toString()
                ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, c['id'].toString()),
          )),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => selectedCustomerId = picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customer = selectedCustomer;
    final enabled = customer != null;
    final total = enabled
        ? contacts.where((e) =>
            e['customer_id']?.toString() == selectedCustomerId).length
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('九宮格')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: chooseCustomer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person_search)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('成交客戶',
                              style: TextStyle(color: Color(0xFF6E788D))),
                            const SizedBox(height: 4),
                            Text(
                              customer == null
                                  ? '請選擇客戶'
                                  : textOf(customer['name']),
                              style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            if (customer != null)
                              Text('目前共推薦 $total 人'),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (index == 4) {
                  return Card(
                    color: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: chooseCustomer,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            customer == null
                                ? '請選擇\n成交客戶'
                                : textOf(customer['name']),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final categoryIndex = index < 4 ? index : index - 1;
                final category = categories[categoryIndex];
                final count = countFor(category);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: !enabled ? () {
                      snack(context, '請先選擇成交客戶');
                    } : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContactCategoryPage(
                            category: category,
                            customerId: selectedCustomerId!,
                            customerName: textOf(customer['name']),
                          ),
                        ),
                      );
                      await load();
                    },
                    child: Opacity(
                      opacity: enabled ? 1 : .45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(enabled ? '$count 人' : '—'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '請先選擇成交客戶，選定後才能查看或新增推薦人脈。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6E788D)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContactCategoryPage extends StatefulWidget {
  const ContactCategoryPage({
    super.key,
    required this.category,
    required this.customerId,
    required this.customerName,
  });

  final String category;
  final String customerId;
  final String customerName;

  @override
  State<ContactCategoryPage> createState() => _ContactCategoryPageState();
}

class _ContactCategoryPageState extends State<ContactCategoryPage> {
  final repo = Repo();
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all = await repo.list('contacts');
    if (!mounted) return;
    setState(() {
      rows = all.where((e) =>
        e['customer_id']?.toString() == widget.customerId &&
        e['category']?.toString() == widget.category
      ).toList();
    });
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    String? status = row?['status']?.toString();
    final name = TextEditingController(text: textOf(row?['name']));
    final phone = TextEditingController(text: textOf(row?['phone']));
    final occupation = TextEditingController(text: textOf(row?['occupation']));
    final company = TextEditingController(text: textOf(row?['company']));
    final notes = TextEditingController(text: textOf(row?['notes']));

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(row == null ? '新增${widget.category}推薦' : '編輯推薦人脈',
                  style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('推薦客戶：${widget.customerName}',
                  style: const TextStyle(color: Color(0xFF6E788D))),
                const SizedBox(height: 18),
                field(name, '姓名 *'),
                field(phone, '手機'),
                field(occupation, '職業'),
                field(company, '公司'),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  hint: const Text('請選擇狀態'),
                  decoration: const InputDecoration(
                    labelText: '狀態',
                    border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: '未聯絡', child: Text('未聯絡')),
                    DropdownMenuItem(value: '已聯絡', child: Text('已聯絡')),
                    DropdownMenuItem(value: '待追蹤', child: Text('待追蹤')),
                    DropdownMenuItem(value: '已成交', child: Text('已成交')),
                  ],
                  onChanged: (value) =>
                    setSheetState(() => status = value),
                ),
                const SizedBox(height: 12),
                field(notes, '備註', maxLines: 3),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('儲存')),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || name.text.trim().isEmpty) return;
    if (status == null) {
      if (mounted) snack(context, '請選擇狀態');
      return;
    }

    final values = {
      'customer_id': widget.customerId,
      'name': name.text.trim(),
      'category': widget.category,
      'status': status,
      'phone': blank(phone.text),
      'occupation': blank(occupation.text),
      'company': blank(company.text),
      'notes': blank(notes.text),
    };

    if (row == null) {
      await repo.insert('contacts', values);
    } else {
      await repo.update('contacts', row['id'].toString(), values);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customerName}｜${widget.category}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.person_add),
        label: const Text('新增推薦')),
      body: rows.isEmpty
          ? Center(
              child: Text(
                '${widget.customerName}目前沒有「${widget.category}」推薦人脈'))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      onTap: () => edit(row),
                      title: Text(textOf(row['name']),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text([
                        textOf(row['occupation']),
                        textOf(row['company']),
                        textOf(row['phone']),
                        textOf(row['status']),
                      ].where((e) => e.isNotEmpty).join('・')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await edit(row);
                          } else {
                            await confirmDelete(context, () async {
                              await repo.remove(
                                'contacts', row['id'].toString());
                              await load();
                            });
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('編輯')),
                          PopupMenuItem(value: 'delete', child: Text('刪除')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  List<Map<String, dynamic>> rows = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final next = await repo.list('todos');
    if (!mounted) return;
    setState(() => rows = next);
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final title = TextEditingController(text: textOf(row?['title']));
    final description =
        TextEditingController(text: textOf(row?['description']));
    final dueAt = TextEditingController(text: textOf(row?['due_at']));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? '新增待辦' : '編輯待辦'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field(title, '待辦事項 *'),
              field(description, '說明', maxLines: 3),
              field(dueAt, '提醒時間（YYYY-MM-DD HH:mm）'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('儲存'),
          ),
        ],
      ),
    );

    if (saved != true || title.text.trim().isEmpty) return;

    final parsedDue = DateTime.tryParse(dueAt.text.replaceFirst(' ', 'T'));
    final values = {
      'title': title.text.trim(),
      'description': blank(description.text),
      'due_at': parsedDue?.toIso8601String(),
      'status': row?['status']?.toString() ?? '待處理',
    };

    if (row == null) {
      await repo.insert('todos', values);
    } else {
      await repo.update('todos', row['id'].toString(), values);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('待辦')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: rows.isEmpty
          ? const Center(child: Text('目前沒有待辦事項'))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final done = row['status'] == '已完成';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CheckboxListTile(
                      value: done,
                      onChanged: (value) async {
                        await repo.update('todos', row['id'].toString(), {
                          'status': value == true ? '已完成' : '待處理',
                          'completed_at':
                              value == true ? DateTime.now().toIso8601String() : null,
                        });
                        await load();
                      },
                      title: Text(
                        textOf(row['title']),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        [
                          textOf(row['description']),
                          formatDateTime(row['due_at']),
                        ].where((e) => e.isNotEmpty).join('\n'),
                      ),
                      secondary: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await edit(row);
                          } else {
                            await confirmDelete(
                              context,
                              () async {
                                await repo.remove('todos', row['id'].toString());
                                await load();
                              },
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('編輯')),
                          PopupMenuItem(value: 'delete', child: Text('刪除')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class PoliciesPage extends StatefulWidget {
  const PoliciesPage({super.key});

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  List<Map<String, dynamic>> rows = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final next = await repo.policies();
    if (!mounted) return;
    setState(() => rows = next);
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final customers = await repo.list('customers');
    if (!mounted) return;
    if (customers.isEmpty) {
      snack(context, '請先新增成交客戶');
      return;
    }

    String? customerId = row?['customer_id']?.toString();
    String? type = row?['policy_type']?.toString();
    final product =
        TextEditingController(text: textOf(row?['product_name']));
    final insurer = TextEditingController(text: textOf(row?['insurer']));
    final premium =
        TextEditingController(text: textOf(row?['annual_premium']));
    final coverage =
        TextEditingController(text: textOf(row?['coverage_amount']));
    final effectiveDate =
        TextEditingController(text: textOf(row?['effective_date']));
    final paymentMethod =
        TextEditingController(text: textOf(row?['payment_method']));
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
                Text(
                  row == null ? '新增保單' : '編輯保單',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: customerId,
                  hint: const Text('請選擇客戶'),
                  decoration: const InputDecoration(
                    labelText: '客戶',
                    border: OutlineInputBorder(),
                  ),
                  items: customers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(textOf(c['name'])),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => customerId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                field(product, '商品名稱 *'),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  hint: const Text('請選擇保單類型'),
                  decoration: const InputDecoration(
                    labelText: '保單類型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    '壽險',
                    '醫療',
                    '重大傷病',
                    '癌症',
                    '長照',
                    '失能',
                    '意外',
                    '投資型',
                    '年金',
                    '其他',
                  ]
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setSheetState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                field(insurer, '保險公司'),
                field(
                  premium,
                  '年繳保費',
                  keyboardType: TextInputType.number,
                ),
                field(
                  coverage,
                  '保額',
                  keyboardType: TextInputType.number,
                ),
                field(effectiveDate, '生效日（YYYY-MM-DD）'),
                field(paymentMethod, '繳費方式'),
                field(notes, '備註', maxLines: 3),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('儲存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || product.text.trim().isEmpty) return;
    if (customerId == null || type == null) {
      if (mounted) snack(context, '請選擇客戶與保單類型');
      return;
    }

    final values = {
      'customer_id': customerId,
      'product_name': product.text.trim(),
      'policy_type': type,
      'insurer': blank(insurer.text),
      'annual_premium': double.tryParse(premium.text) ?? 0,
      'coverage_amount': double.tryParse(coverage.text) ?? 0,
      'effective_date': blank(effectiveDate.text),
      'payment_method': blank(paymentMethod.text),
      'notes': blank(notes.text),
    };

    if (row == null) {
      await repo.insert('policies', values);
    } else {
      await repo.update('policies', row['id'].toString(), values);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currency = NumberFormat.decimalPattern('zh_TW');

    return Scaffold(
      appBar: AppBar(title: const Text('保單管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: rows.isEmpty
          ? const Center(child: Text('尚無保單資料'))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final customer =
                      (row['customers'] as Map<String, dynamic>?)?['name'] ?? '';
                  final premium =
                      double.tryParse(textOf(row['annual_premium'])) ?? 0;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      onTap: () => edit(row),
                      leading: const CircleAvatar(
                        child: Icon(Icons.description),
                      ),
                      title: Text(
                        textOf(row['product_name']),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '$customer・${textOf(row['policy_type'])}・${textOf(row['insurer'])}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await edit(row);
                          } else {
                            await confirmDelete(
                              context,
                              () async {
                                await repo.remove(
                                  'policies',
                                  row['id'].toString(),
                                );
                                await load();
                              },
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Text('\$${currency.format(premium)}'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('編輯'),
                          ),
                          const PopupMenuItem(
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
    );
  }
}

Widget field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6E788D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? '未填寫' : value)),
      ],
    ),
  );
}

Widget sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    ),
  );
}

String textOf(dynamic value) => value?.toString() ?? '';

String? blank(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String formatDateTime(dynamic raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return '';
  final dt = DateTime.tryParse(value)?.toLocal();
  if (dt == null) return value;
  return DateFormat('yyyy/MM/dd HH:mm').format(dt);
}

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<void> confirmDelete(
  BuildContext context,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('確認刪除'),
      content: const Text('刪除後無法復原，確定繼續嗎？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('刪除'),
        ),
      ],
    ),
  );
  if (confirmed == true) await action();
}
