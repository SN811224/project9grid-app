import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vgmtonkdgikpfnlkskqm.supabase.co';
const supabaseKey = 'sb_publishable_vpgCkWsA2k69mh9Z2W__cg_Szbz4Iko';

const navy = Color(0xFF214D8D);
const bg = Color(0xFFF3F6FB);
final ValueNotifier<int> shellIndexNotifier = ValueNotifier<int>(0);
final ValueNotifier<int> prospectsRefreshNotifier = ValueNotifier<int>(0);
const passwordRecoveryRedirect = 'https://sn811224.github.io/project9grid-app/';

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
                '客戶名單總表 發生畫面錯誤\n\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
  runApp(const Project9GridBootstrap());
}

String formatRocBirthday(dynamic value) {
  if (value == null) return '';
  final raw = value.toString().trim();
  if (raw.isEmpty) return '';

  final normalized = raw
      .replaceAll('民國', '')
      .replaceAll('年', '-')
      .replaceAll('月', '-')
      .replaceAll('日', '')
      .replaceAll('/', '-')
      .replaceAll('.', '-');

  final parts = normalized.split('-').where((e) => e.isNotEmpty).toList();
  if (parts.length != 3) return raw;

  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return raw;

  final rocYear = y >= 1911 ? y - 1911 : y;
  return '$rocYear.${m.toString().padLeft(2, '0')}.${d.toString().padLeft(2, '0')}';
}

String nameWithRocBirthday(dynamic name, dynamic birthday) {
  final n = name?.toString().trim() ?? '';
  final b = formatRocBirthday(birthday);
  return [n, b].where((e) => e.isNotEmpty).join('　');
}

String? normalizeBirthdayInput(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final normalized = value
      .replaceAll('民國', '')
      .replaceAll('年', '-')
      .replaceAll('月', '-')
      .replaceAll('日', '')
      .replaceAll('/', '-')
      .replaceAll('.', '-');

  final parts = normalized.split('-').where((e) => e.isNotEmpty).toList();
  if (parts.length != 3) return '__INVALID__';

  final yearText = parts[0];
  final year = int.tryParse(yearText);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return '__INVALID__';

  int westernYear;
  if (yearText.length == 4 && year >= 1911) {
    westernYear = year;
  } else if (yearText.length == 2 || yearText.length == 3) {
    westernYear = year + 1911;
  } else {
    return '__INVALID__';
  }

  final date = DateTime(westernYear, month, day);
  if (date.year != westernYear || date.month != month || date.day != day) {
    return '__INVALID__';
  }

  return '${westernYear.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

bool isValidPhoneInput(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return true;
  final compact = value.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(compact);
}

Future<void> showFormWarning(BuildContext context, String message) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('輸入資料有誤'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('確定'),
        ),
      ],
    ),
  );
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
      title: '客戶名單總表',
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
                    Text('客戶名單總表 啟動中…'),
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
                      '無法啟動 客戶名單總表',
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
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordPage();
        }
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
  DateTime? authCooldownUntil;

  String authErrorMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('email rate limit exceeded') || m.contains('rate limit')) {
      return '驗證信寄送次數已達系統上限，請稍後再試。若持續發生，請提高 Supabase Auth Email Rate Limit 或設定自有 SMTP。';
    }
    if (m.contains('user already registered')) {
      return '此 Email 已建立帳號，請改用登入。';
    }
    if (m.contains('invalid login credentials')) {
      return 'Email 或密碼錯誤。';
    }
    if (m.contains('email not confirmed')) {
      return 'Email 尚未完成驗證，請先至信箱點擊驗證連結。';
    }
    return message;
  }

  Future<void> submit() async {
    final now = DateTime.now();
    if (authCooldownUntil != null && now.isBefore(authCooldownUntil!)) {
      final seconds = authCooldownUntil!.difference(now).inSeconds + 1;
      toast('操作過於頻繁，請約 $seconds 秒後再試');
      return;
    }
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
      if (e.message.toLowerCase().contains('rate limit')) {
        authCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
      }
      toast(authErrorMessage(e.message));
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
      await Supabase.instance.client.auth.resetPasswordForEmail(
        value,
        redirectTo: passwordRecoveryRedirect,
      );
      toast('密碼重設信已寄出，請到信箱點連結設定新密碼');
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('rate limit')) {
        authCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
      }
      toast(authErrorMessage(e.message));
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      MediaQuery.of(context).viewInsets.bottom -
                      48,
                ),
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
                              '客戶名單總表',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: password,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!loading) submit();
                              },
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
                              onPressed: () => setState(
                                () => registerMode = !registerMode,
                              ),
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
          },
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final p1 = password.text;
    final p2 = confirmPassword.text;

    if (p1.length < 6) {
      toast('新密碼至少需要 6 碼');
      return;
    }
    if (p1 != p2) {
      toast('兩次輸入的密碼不一致');
      return;
    }

    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: p1),
      );
      toast('密碼修改完成，請重新登入');
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      toast(e.message);
    } catch (e) {
      toast('密碼修改失敗：$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
                    const Icon(Icons.lock_reset, size: 58),
                    const SizedBox(height: 16),
                    const Text(
                      '設定新密碼',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '請輸入新的登入密碼',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: '新密碼',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPassword,
                      obscureText: obscure,
                      onSubmitted: (_) => loading ? null : save(),
                      decoration: const InputDecoration(
                        labelText: '再次輸入新密碼',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: loading ? null : save,
                      icon: const Icon(Icons.save_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Text(loading ? '處理中…' : '儲存新密碼'),
                      ),
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

  Future<Map<String, dynamic>> insertReturning(
    String table,
    Map<String, dynamic> values,
  ) async {
    final row = await client
        .from(table)
        .insert({'user_id': uid, ...values})
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> recruitmentLogs(
      String recruitmentId) async {
    final rows = await client
        .from('recruitment_logs')
        .select()
        .eq('user_id', uid)
        .eq('recruitment_id', recruitmentId)
        .order('recruited_on', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> engagementLogs(String prospectId) async {
    final rows = await client
        .from('engagement_logs')
        .select()
        .eq('user_id', uid)
        .eq('prospect_id', prospectId)
        .order('engaged_on', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> prospectBySourceContact(
      String contactId) async {
    final rows = await client
        .from('prospects')
        .select()
        .eq('user_id', uid)
        .eq('source_contact_id', contactId)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.isEmpty ? null : list.first;
  }

  Future<List<Map<String, dynamic>>> policyRiders(String policyId) async {
    final rows = await client
        .from('policy_riders')
        .select()
        .eq('user_id', uid)
        .eq('policy_id', policyId)
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> replacePolicyRiders(
    String policyId,
    List<Map<String, dynamic>> riders,
  ) async {
    await client
        .from('policy_riders')
        .delete()
        .eq('user_id', uid)
        .eq('policy_id', policyId);
    if (riders.isEmpty) return;
    await client.from('policy_riders').insert(
          riders
              .map((e) => {'user_id': uid, 'policy_id': policyId, ...e})
              .toList(),
        );
  }

  Future<void> update(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    await client.from(table).update(values).eq('id', id).eq('user_id', uid);
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
    final prospects = await list('prospects');
    List<Map<String, dynamic>> recruitments = [];
    try {
      recruitments = await list('recruitments');
    } catch (_) {}
    return {
      'customers': customers.length,
      'contacts': contacts.length,
      'prospects': prospects.where((e) => e['status'] != '已轉客戶').length,
      'recruitments': recruitments.length,
    };
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late int index;

  final pages = const [
    DashboardPage(),
    CustomersPage(),
    GridPage(),
    ProspectsPage(),
    RecruitmentPage(),
  ];

  @override
  void initState() {
    super.initState();
    index = shellIndexNotifier.value;
    shellIndexNotifier.addListener(_syncIndex);
  }

  void _syncIndex() {
    if (!mounted) return;
    setState(() => index = shellIndexNotifier.value);
  }

  @override
  void dispose() {
    shellIndexNotifier.removeListener(_syncIndex);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: mainNavigationBar(context, index),
    );
  }
}

NavigationBar mainNavigationBar(BuildContext context, int currentIndex) {
  return NavigationBar(
    selectedIndex: currentIndex,
    height: 72,
    onDestinationSelected: (value) {
      shellIndexNotifier.value = value;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    },
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home), label: '首頁'),
      NavigationDestination(icon: Icon(Icons.people), label: '客戶'),
      NavigationDestination(icon: Icon(Icons.grid_view), label: '九宮格'),
      NavigationDestination(icon: Icon(Icons.handshake_outlined), label: '經營'),
      NavigationDestination(icon: Icon(Icons.group_add_outlined), label: '增員'),
    ],
  );
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
    'prospects': 0,
    'recruitments': 0,
  };
  List<Map<String, dynamic>> birthdays = [];
  double gridCompletion = 0;
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
    final contacts = await repo.list('contacts');
    final now = DateTime.now();

    const gridCategories = [
      '親戚',
      '同學',
      '鄰居',
      '同事',
      '前同事',
      '家人',
      '朋友',
      '社團',
    ];
    var filledSlots = 0;
    for (final customer in customers) {
      final customerId = customer['id'].toString();
      for (final category in gridCategories) {
        if (contacts.any((e) =>
            e['customer_id']?.toString() == customerId &&
            e['category']?.toString() == category)) {
          filledSlots++;
        }
      }
    }
    final completion = customers.isEmpty
        ? 0.0
        : filledSlots / (customers.length * gridCategories.length);

    // 壽星區間：本月全部 + 下個月 1～5 日；同時納入成交客戶與九宮格人脈。
    final birthdayPool = <Map<String, dynamic>>[
      ...customers.map((e) => {...e, '_birthday_source': '客戶'}),
      ...contacts.map((e) => {...e, '_birthday_source': '九宮格'}),
    ];
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final upcoming = birthdayPool.where((row) {
      final raw = row['birthday']?.toString();
      final birthday = raw == null ? null : DateTime.tryParse(raw);
      if (birthday == null) return false;
      return birthday.month == now.month ||
          (birthday.month == nextMonth && birthday.day <= 5);
    }).toList()
      ..sort((a, b) {
        final ad = DateTime.tryParse(a['birthday']?.toString() ?? '');
        final bd = DateTime.tryParse(b['birthday']?.toString() ?? '');
        if (ad == null || bd == null) return 0;
        final ak = ad.month == now.month ? ad.day : 100 + ad.day;
        final bk = bd.month == now.month ? bd.day : 100 + bd.day;
        return ak.compareTo(bk);
      });

    if (!mounted) return;
    setState(() {
      counts = newCounts;
      birthdays = upcoming;
      gridCompletion = completion.clamp(0.0, 1.0);
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
              kicker: '客戶名單總表',
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
                      MetricCard(value: counts['prospects']!, label: '經營名單'),
                      MetricCard(
                        value: counts['recruitments']!,
                        label: '增員名單',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecruitmentPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.cake_outlined),
                            SizedBox(width: 12),
                            Text('本月壽星',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 17)),
                          ]),
                          const SizedBox(height: 10),
                          if (birthdays.isEmpty)
                            const Text('本月及下月 5 日前沒有壽星')
                          else
                            ...birthdays.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${nameWithRocBirthday(b['name'], b['birthday'])}  ・ ${textOf(b['_birthday_source'])}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                )),
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
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '九宮格平均完成度',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                loading
                                    ? '—'
                                    : '${(gridCompletion * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loading ? '計算中' : '每位成交客戶 8 格；該格有至少 1 位人脈即算完成',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E788D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: loading ? null : gridCompletion,
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
  const MetricCard({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
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
                  (e) => Card(
                    child: ListTile(
                      title: Text(textOf(e['product_name'])),
                      subtitle: Text(
                        '${textOf(e['insurer'])}・${textOf(e['payment_frequency'] ?? e['payment_method'])}',
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
                  onTap: () => editFollowLog(e),
                  leading: const Icon(Icons.history),
                  title: Text(textOf(e['summary'])),
                  subtitle: Text(
                    '${textOf(e['channel'])}・${formatDateOnly(e['contacted_at'])}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await editFollowLog(e);
                      } else if (value == 'delete') {
                        await confirmDelete(context, () async {
                          await repo.remove('follow_logs', e['id'].toString());
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
    return contacts
        .where((e) =>
            e['customer_id']?.toString() == selectedCustomerId &&
            e['category']?.toString() == category)
        .length;
  }

  Future<void> chooseCustomer() async {
    if (customers.isEmpty) {
      snack(context, '目前沒有成交客戶，請先到「客戶」新增');
      return;
    }
    final search = TextEditingController();
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final q = search.text.trim().toLowerCase();
          final filtered = customers.where((c) {
            if (q.isEmpty) return true;
            return textOf(c['name']).toLowerCase().contains(q) ||
                textOf(c['phone']).toLowerCase().contains(q);
          }).toList();
          return SizedBox(
            height: MediaQuery.of(context).size.height * .78,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  const Expanded(
                      child: Text('選擇成交客戶',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: search,
                  autofocus: true,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '搜尋姓名或電話',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('清除選擇'),
                onTap: () => Navigator.pop(context, ''),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('找不到符合的成交客戶'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return ListTile(
                            title: Text(textOf(c['name'])),
                            trailing: selectedCustomerId == c['id'].toString()
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () =>
                                Navigator.pop(context, c['id'].toString()),
                          );
                        },
                      ),
              ),
            ]),
          );
        },
      ),
    );
    search.dispose();
    if (picked == null) return;
    setState(() => selectedCustomerId = picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customer = selectedCustomer;
    final enabled = customer != null;
    final total = enabled
        ? contacts
            .where((e) => e['customer_id']?.toString() == selectedCustomerId)
            .length
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('九宮格')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customer == null
                                    ? '點此選擇\n成交客戶'
                                    : textOf(customer['name']),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16),
                              ),
                              if (customer != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '推薦 $total 人',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
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
                    onTap: !enabled
                        ? () {
                            snack(context, '請先選擇成交客戶');
                          }
                        : () async {
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
                  '請點九宮格中央選擇成交客戶，選定後才能查看或新增推薦人脈。',
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
      rows = all
          .where((e) =>
              e['customer_id']?.toString() == widget.customerId &&
              e['category']?.toString() == widget.category)
          .toList();
    });
  }

  Future<void> syncProspect(
    String contactId,
    Map<String, dynamic> values,
  ) async {
    final existing = await repo.prospectBySourceContact(contactId);
    final prospectValues = {
      'name': values['name'],
      'phone': values['phone'],
      'birthday': values['birthday'],
      'occupation': values['occupation'],
      'company': values['company'],
      'notes': values['notes'],
      'source_customer_id': widget.customerId,
      'source_contact_id': contactId,
      'source_category': widget.category,
      'referred_by_name': '${widget.customerName}${widget.category}',
      'status': existing?['status']?.toString() == '已轉客戶'
          ? '已轉客戶'
          : (values['status']?.toString() ?? '未聯絡'),
    };
    if (existing == null) {
      await repo.insert('prospects', prospectValues);
    } else if (existing['status'] != '已轉客戶') {
      await repo.update('prospects', existing['id'].toString(), prospectValues);
    }

    // 九宮格新增或修改推薦後，立即刷新「經營」名單。
    prospectsRefreshNotifier.value++;
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    String? status = row?['status']?.toString() == '已聯絡'
        ? '經營中'
        : (row?['status']?.toString() ?? '未聯絡');
    final name = TextEditingController(text: textOf(row?['name']));
    final phone = TextEditingController(text: textOf(row?['phone']));
    final birthday =
        TextEditingController(text: formatRocBirthday(row?['birthday']));
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
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (row == null)
                  addModalHeader(
                    context,
                    '新增${widget.category}推薦',
                    () => [
                      name.text,
                      phone.text,
                      birthday.text,
                      occupation.text,
                      company.text,
                      notes.text,
                    ].any((e) => e.trim().isNotEmpty),
                  )
                else
                  const Text(
                    '編輯推薦人脈',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 6),
                Text('推薦客戶：${widget.customerName}',
                    style: const TextStyle(color: Color(0xFF6E788D))),
                const SizedBox(height: 18),
                field(name, '姓名 *'),
                field(phone, '手機'),
                field(birthday, '生日（民國YYY-MM-DD）'),
                field(occupation, '職業'),
                field(company, '公司'),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                      labelText: '目前狀態', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: '未聯絡', child: Text('未聯絡')),
                    DropdownMenuItem(value: '經營中', child: Text('經營中')),
                    DropdownMenuItem(value: '待成交', child: Text('待成交')),
                    DropdownMenuItem(value: '已成交', child: Text('已成交')),
                  ],
                  onChanged: (value) => setSheetState(() => status = value),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == '已成交'
                          ? const Color(0xFFE5F4E9)
                          : status == '待成交'
                              ? const Color(0xFFFFF0DA)
                              : const Color(0xFFE8EEF9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '目前：${status ?? '未聯絡'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: status == '已成交'
                            ? Colors.green.shade700
                            : status == '待成交'
                                ? Colors.orange.shade800
                                : navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                field(notes, '備註', maxLines: 3),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '新增推薦後，會自動加入「經營」名單。',
                      style: TextStyle(color: Color(0xFF6E788D)),
                    ),
                  ),
                ),
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
                      if (normalizeBirthdayInput(birthday.text) ==
                          '__INVALID__') {
                        await showFormWarning(
                            context, '生日格式不正確。請輸入民國年，例如 81-12-24 或 081-12-24。');
                        return;
                      }
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    child: const Text('儲存')),
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
      await showFormWarning(context, '生日格式不正確。請輸入民國年，例如 81-12-24 或 081-12-24。');
      return;
    }
    final values = {
      'customer_id': widget.customerId,
      'name': name.text.trim(),
      'category': widget.category,
      'status': status ?? '未聯絡',
      'phone': blank(phone.text),
      'birthday': normalizedBirthday,
      'occupation': blank(occupation.text),
      'company': blank(company.text),
      'notes': blank(notes.text),
    };

    Map<String, dynamic>? savedContact;
    try {
      if (row == null) {
        final contact = await repo.insertReturning('contacts', values);
        savedContact = contact;
        await syncProspect(contact['id'].toString(), values);

        if (mounted) {
          setState(() {
            rows = [
              ...rows,
              contact,
            ];
          });
        }
      } else {
        await repo.update('contacts', row['id'].toString(), values);
        savedContact = {
          ...row,
          ...values,
          'id': row['id'],
        };
        await syncProspect(row['id'].toString(), values);

        if (mounted) {
          setState(() {
            rows = rows
                .map((e) => e['id'].toString() == row['id'].toString()
                    ? {...e, ...values}
                    : e)
                .toList();
          });
        }
      }

      await load();

      if (!mounted) return;
      snack(context, '目前狀態已更新為「${status ?? '未聯絡'}」');

      final alreadyConverted = savedContact?['converted_customer_id'] != null;
      if ((status ?? '未聯絡') == '已成交' &&
          !alreadyConverted &&
          savedContact != null) {
        await convertToCustomer(savedContact);
      }
    } catch (e) {
      if (mounted) {
        snack(context, '狀態更新失敗：$e');
      }
    }
  }

  Future<void> convertToCustomer(Map<String, dynamic> row) async {
    if (row['converted_customer_id'] != null) {
      if (mounted) snack(context, '這位推薦人已經轉為客戶');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('轉為成交客戶'),
        content: Text('將「${textOf(row['name'])}」加入成交客戶名單？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('確認轉入')),
        ],
      ),
    );
    if (ok != true) return;

    final customer = await repo.insertReturning('customers', {
      'name': textOf(row['name']),
      'phone': row['phone'],
      'birthday': row['birthday'],
      'occupation': row['occupation'],
      'company': row['company'],
      'notes': row['notes'],
      'closed_date': DateTime.now().toIso8601String().split('T').first,
      'referred_by_customer_id': widget.customerId,
      'source_contact_id': row['id'].toString(),
    });

    await repo.update('contacts', row['id'].toString(), {
      'status': '已成交',
      'converted_customer_id': customer['id'].toString(),
    });
    final prospect = await repo.prospectBySourceContact(row['id'].toString());
    if (prospect != null) {
      await repo.update('prospects', prospect['id'].toString(), {
        'status': '已轉客戶',
        'converted_customer_id': customer['id'].toString(),
      });
    }
    if (mounted) snack(context, '已轉入成交客戶，推薦關係已保留');
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: mainNavigationBar(context, 2),
      appBar: AppBar(title: Text('${widget.customerName}｜${widget.category}')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => edit(),
          icon: const Icon(Icons.person_add),
          label: const Text('新增推薦')),
      body: rows.isEmpty
          ? Center(
              child: Text('${widget.customerName}目前沒有「${widget.category}」推薦人脈'))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final converted = row['converted_customer_id'] != null;
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      onTap: () => edit(row),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nameWithRocBirthday(row['name'], row['birthday']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: converted || textOf(row['status']) == '已成交'
                                  ? const Color(0xFFE5F4E9)
                                  : textOf(row['status']) == '待成交'
                                      ? const Color(0xFFFFF0DA)
                                      : (textOf(row['status']).trim().isEmpty ||
                                              textOf(row['status']).trim() ==
                                                  '未聯絡')
                                          ? const Color(0xFFFFE5E5)
                                          : const Color(0xFFE8EEF9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              converted ? '已成交' : textOf(row['status']),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: converted ||
                                        textOf(row['status']) == '已成交'
                                    ? Colors.green.shade700
                                    : textOf(row['status']) == '待成交'
                                        ? Colors.orange.shade800
                                        : (textOf(row['status'])
                                                    .trim()
                                                    .isEmpty ||
                                                textOf(row['status']).trim() ==
                                                    '未聯絡')
                                            ? Colors.red.shade700
                                            : navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text([
                        textOf(row['occupation']),
                        textOf(row['company']),
                        textOf(row['phone']),
                      ].where((e) => e.isNotEmpty).join('・')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await edit(row);
                          } else if (value == 'convert') {
                            await convertToCustomer(row);
                          } else {
                            await confirmDelete(context, () async {
                              await repo.remove(
                                  'contacts', row['id'].toString());
                              await load();
                            });
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('編輯')),
                          if (!converted)
                            const PopupMenuItem(
                                value: 'convert', child: Text('轉為成交客戶')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('刪除')),
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

class ProspectsPage extends StatefulWidget {
  const ProspectsPage({super.key});
  @override
  State<ProspectsPage> createState() => _ProspectsPageState();
}

class _ProspectsPageState extends State<ProspectsPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> progressLogs = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final next = await repo.list('prospects');
    final logs = await repo.list('engagement_logs');
    if (mounted) {
      setState(() {
        rows = next;
        progressLogs = logs;
      });
    }
  }

  DateTime? lastProgressFor(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final dates = progressLogs
        .where((e) => e['prospect_id']?.toString() == id)
        .map((e) => parseAnyDate(e['engaged_on'] ?? e['engaged_at']))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isNotEmpty) return dates.first;
    return parseAnyDate(row['created_at']);
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: textOf(row?['name']));
    final phone = TextEditingController(text: textOf(row?['phone']));
    final lineId = TextEditingController(text: textOf(row?['line_id']));
    final birthday = TextEditingController(text: textOf(row?['birthday']));
    final occupation = TextEditingController(text: textOf(row?['occupation']));
    final company = TextEditingController(text: textOf(row?['company']));
    final family = TextEditingController(text: textOf(row?['family_status']));
    final notes = TextEditingController(text: textOf(row?['notes']));
    int priority = int.tryParse(textOf(row?['priority'])) ?? 0;

    String status =
        textOf(row?['status']).isEmpty ? '未聯絡' : textOf(row?['status']);

    // 舊資料「待成交」自動轉成新名稱「待成交」
    if (status == '待成交') {
      status = '待成交';
    }

    String sourceType = textOf(row?['source_category']).isEmpty
        ? '自行新增'
        : textOf(row?['source_category']);
    final referredBy = TextEditingController(
      text: textOf(row?['referred_by_name']),
    );
    const sourceOptions = [
      '自行新增',
      '親戚',
      '同學',
      '鄰居',
      '同事',
      '前同事',
      '家人',
      '朋友',
      '社團',
      '其他',
    ];
    if (!sourceOptions.contains(sourceType)) {
      sourceType = '其他';
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(children: [
          if (row == null)
            addModalHeader(
              context,
              '新增經營名單',
              () => [
                name.text,
                phone.text,
                lineId.text,
                birthday.text,
                occupation.text,
                company.text,
                family.text,
                notes.text
              ].any((e) => e.trim().isNotEmpty),
            )
          else
            const Text('編輯經營名單',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          field(name, '姓名 *'),
          field(phone, '手機'),
          field(lineId, 'LINE ID'),
          field(birthday, '生日（民國YYY-MM-DD）'),
          field(occupation, '職業'),
          field(company, '公司'),
          field(family, '家庭狀況'),
          DropdownButtonFormField<String>(
            initialValue: sourceType,
            decoration: const InputDecoration(
              labelText: '來源',
              border: OutlineInputBorder(),
            ),
            items: sourceOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) sourceType = value;
            },
          ),
          const SizedBox(height: 12),
          if (sourceType != '自行新增') field(referredBy, '來源'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: priority >= 1 && priority <= 5 ? priority : null,
            decoration: const InputDecoration(
              labelText: '成交機會',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              5,
              (index) {
                final value = index + 1;
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '${'★' * value}${'☆' * (5 - value)}',
                  ),
                );
              },
            ),
            onChanged: (value) {
              if (value != null) priority = value;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: [
              '未聯絡',
              '經營中',
              '待成交',
              '已成交',
            ].contains(status)
                ? status
                : '未聯絡',
            decoration: const InputDecoration(
              labelText: '狀態',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: '未聯絡',
                child: Text('未聯絡'),
              ),
              DropdownMenuItem(
                value: '經營中',
                child: Text('經營中'),
              ),
              DropdownMenuItem(
                value: '待成交',
                child: Text('待成交'),
              ),
              DropdownMenuItem(
                value: '已成交',
                child: Text('已成交'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                status = value;
              }
            },
          ),
          const SizedBox(height: 12),
          field(notes, '備註', maxLines: 4),
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
              child: const Text('儲存')),
        ])),
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
      'source_category': sourceType,
      'referred_by_name':
          sourceType == '自行新增' ? '自行新增' : blank(referredBy.text),
      'priority': priority,
      'notes': blank(notes.text),
      'status': status,
    };
    try {
      if (row == null) {
        await repo.insert('prospects', values);
      } else {
        await repo.update('prospects', row['id'].toString(), values);

        // 經營名單狀態同步回九宮格原始人脈
        final sourceContactId = textOf(row['source_contact_id']);
        if (sourceContactId.isNotEmpty) {
          await repo.update(
            'contacts',
            sourceContactId,
            {
              'status': status,
            },
          );
        }
      }
      await load();
    } catch (e) {
      if (context.mounted) {
        await showFormWarning(
          context,
          '儲存失敗：$e',
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final k = search.text.trim().toLowerCase();
    final active = rows.where((e) => e['status'] != '已轉客戶').where((e) {
      final h = [
        e['name'],
        e['phone'],
        e['occupation'],
        e['company'],
        e['notes'],
        e['referred_by_name']
      ].whereType<Object>().join(' ').toLowerCase();
      return k.isEmpty || h.contains(k);
    }).toList()
      ..sort((a, b) {
        final pa = int.tryParse(textOf(a['priority'])) ?? 0;
        final pb = int.tryParse(textOf(b['priority'])) ?? 0;

        final byPriority = pb.compareTo(pa);
        if (byPriority != 0) return byPriority;

        final la = followUpLightFor(lastProgressFor(a));
        final lb = followUpLightFor(lastProgressFor(b));
        final byLight = followUpPriority(la).compareTo(followUpPriority(lb));
        if (byLight != 0) return byLight;

        final da = lastProgressFor(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = lastProgressFor(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('經營')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => edit(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('新增經營')),
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
                    hintText: '搜尋姓名、手機、職業、公司或備註',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none)))),
        Expanded(
            child: active.isEmpty
                ? const Center(child: Text('目前沒有經營名單'))
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                        itemCount: active.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final row = active[index];
                          final referredByName =
                              textOf(row['referred_by_name']).isNotEmpty
                                  ? textOf(row['referred_by_name'])
                                  : (textOf(row['source_category']).isEmpty
                                      ? '自行新增'
                                      : textOf(row['source_category']));
                          return Card(
                              child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProspectDetailPage(prospect: row)));
                              await load();
                            },
                            title: Row(children: [
                              followUpDot(
                                followUpLightFor(lastProgressFor(row)),
                                size: 10,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  nameWithRocBirthday(
                                      row['name'], row['birthday']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (textOf(row['status']).isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    final statusPriorityValue =
                                        int.tryParse(textOf(row['priority'])) ??
                                            0;
                                    final statusStarCount =
                                        statusPriorityValue.clamp(0, 5);
                                    final statusStars =
                                        List.filled(statusStarCount, '★')
                                            .join();

                                    return SizedBox(
                                      width: 92,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: textOf(row['status']) ==
                                                        '待成交'
                                                    ? const Color(0xFFFFF0DA)
                                                    : textOf(row['status']) ==
                                                            '已成交'
                                                        ? const Color(
                                                            0xFFE5F4E9)
                                                        : const Color(
                                                            0xFFE8EEF8),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                textOf(row['status']),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: textOf(
                                                              row['status']) ==
                                                          '待成交'
                                                      ? Colors.orange.shade800
                                                      : textOf(row['status']) ==
                                                              '已成交'
                                                          ? Colors
                                                              .green.shade700
                                                          : navy,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (statusStarCount > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 3, right: 6),
                                              child: SizedBox(
                                                width: 86,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    statusStars,
                                                    textAlign: TextAlign.right,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ]),
                            subtitle: Builder(
                              builder: (context) {
                                final priorityValue =
                                    int.tryParse(textOf(row['priority'])) ?? 0;
                                final starCount = priorityValue.clamp(0, 5);
                                final stars =
                                    '★' * starCount + '☆' * (5 - starCount);

                                return Text([
                                  textOf(row['phone']),
                                  '來源：$referredByName',
                                ].where((e) => e.isNotEmpty).join('\n'));
                              },
                            ),
                            trailing: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await edit(row);
                                } else if (v == 'delete') {
                                  await confirmDelete(context, () async {
                                    await repo.remove(
                                      'prospects',
                                      row['id'].toString(),
                                    );
                                    await load();
                                  });
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
                          ));
                        }))),
      ]),
    );
  }
}

class ProspectDetailPage extends StatefulWidget {
  const ProspectDetailPage({super.key, required this.prospect});
  final Map<String, dynamic> prospect;
  @override
  State<ProspectDetailPage> createState() => _ProspectDetailPageState();
}

class _ProspectDetailPageState extends State<ProspectDetailPage> {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> logs = [];
  String get prospectId => widget.prospect['id'].toString();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await repo.engagementLogs(prospectId);
    if (mounted) setState(() => logs = x);
  }

  Future<void> addLog() async {
    final when = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final status = TextEditingController();
    final content = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(children: [
          addModalHeader(
            context,
            '新增經營紀錄',
            () =>
                status.text.trim().isNotEmpty || content.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 18),
          field(when, '經營日期（YYYY-MM-DD）'),
          field(status, '目前經營狀況'),
          field(content, '經營備註 / 內容 *', maxLines: 5),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('儲存本次紀錄')),
        ])),
      ),
    );
    if (saved != true || content.text.trim().isEmpty) return;
    final date = parseFormDate(when.text) ?? DateTime.now();
    try {
      await repo.insert('engagement_logs', {
        'prospect_id': prospectId,
        'engaged_on': DateFormat('yyyy-MM-dd').format(date),
        'engaged_at': DateTime(
          date.year,
          date.month,
          date.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
          DateTime.now().millisecond,
        ).toIso8601String(),
        'status_note': blank(status.text),
        'content': content.text.trim(),
      });
      await load();
      if (mounted) snack(context, '經營紀錄已新增');
    } catch (e) {
      if (mounted) snack(context, '經營紀錄儲存失敗：$e');
    }
  }

  Future<void> editLog(Map<String, dynamic> row) async {
    final when = TextEditingController(
        text: formatDateOnly(row['engaged_on'] ?? row['engaged_at']));
    final status = TextEditingController(text: textOf(row['status_note']));
    final content = TextEditingController(text: textOf(row['content']));

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('修改經營紀錄',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            field(when, '經營日期（YYYY-MM-DD）'),
            field(status, '目前經營狀況'),
            field(content, '經營備註 / 內容 *', maxLines: 5),
            FilledButton.icon(
                onPressed: () {
                  if (content.text.trim().isEmpty) {
                    snack(context, '請輸入經營內容');
                    return;
                  }
                  if (parseFormDate(when.text) == null) {
                    snack(context,
                        '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('儲存修改')),
          ]),
        ),
      ),
    );

    if (saved != true) return;
    if (content.text.trim().isEmpty) {
      if (mounted) snack(context, '請輸入經營內容');
      return;
    }
    final date = parseFormDate(when.text);
    if (date == null) {
      if (mounted)
        snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
      return;
    }

    try {
      await repo.update('engagement_logs', row['id'].toString(), {
        'engaged_on': DateFormat('yyyy-MM-dd').format(date),
        'engaged_at':
            DateTime(date.year, date.month, date.day).toIso8601String(),
        'status_note': blank(status.text),
        'content': content.text.trim(),
      });
      await load();
      if (mounted) snack(context, '經營紀錄已修改');
    } catch (e) {
      if (mounted) snack(context, '經營紀錄修改失敗：$e');
    }
  }

  Future<void> convert() async {
    final p = widget.prospect;
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('轉為成交客戶'),
                content:
                    Text('將「${textOf(p['name'])}」轉入客戶名單？\n原推薦關係與經營紀錄都會保留。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('轉入客戶')),
                ]));
    if (ok != true) return;
    final c = await repo.insertReturning('customers', {
      'name': textOf(p['name']),
      'phone': p['phone'],
      'line_id': p['line_id'],
      'birthday': p['birthday'],
      'occupation': p['occupation'],
      'company': p['company'],
      'family_status': p['family_status'],
      'notes': p['notes'],
      'closed_date': DateTime.now().toIso8601String().split('T').first,
      'source_prospect_id': prospectId,
      'referred_by_customer_id': p['source_customer_id'],
      'source_contact_id': p['source_contact_id'],
    });
    await repo.update('prospects', prospectId,
        {'status': '已轉客戶', 'converted_customer_id': c['id'].toString()});
    final contactId = textOf(p['source_contact_id']);
    if (contactId.isNotEmpty) {
      await repo.update('contacts', contactId,
          {'status': '已成交', 'converted_customer_id': c['id'].toString()});
    }
    if (mounted) {
      snack(context, '已加入成交客戶，推薦鏈已保留');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prospect;
    final k = search.text.trim().toLowerCase();
    final filtered = logs
        .where((e) =>
            k.isEmpty ||
            [e['content'], e['status_note'], e['engaged_on']]
                .whereType<Object>()
                .join(' ')
                .toLowerCase()
                .contains(k))
        .toList();

    // 經營歷程顯示排序：最新新增永遠在最上面
    filtered.sort((a, b) {
      DateTime recordTime(Map<String, dynamic> e) {
        return parseAnyDate(e['engaged_at']) ??
            parseAnyDate(e['engaged_on']) ??
            parseAnyDate(e['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      final result = recordTime(b).compareTo(recordTime(a));
      if (result != 0) return result;

      return textOf(b['id']).compareTo(textOf(a['id']));
    });

    return Scaffold(
      appBar: AppBar(title: Text(textOf(p['name']))),
      bottomNavigationBar: mainNavigationBar(context, 3),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: addLog,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('新增經營紀錄')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      infoRow('手機', textOf(p['phone'])),
                      infoRow('LINE', textOf(p['line_id'])),
                      infoRow('生日', formatRocBirthday(p['birthday'])),
                      infoRow('職業', textOf(p['occupation'])),
                      infoRow('公司', textOf(p['company'])),
                      infoRow('家庭', textOf(p['family_status'])),
                      infoRow(
                        '來源',
                        textOf(p['referred_by_name']).isNotEmpty
                            ? textOf(p['referred_by_name'])
                            : (textOf(p['source_category']).isEmpty
                                ? '自行新增'
                                : textOf(p['source_category'])),
                      ),
                      infoRow('備註', textOf(p['notes'])),
                    ]))),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text(
                  '目前狀態',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: Text(
                  textOf(p['status']).isEmpty ? '未聯絡' : textOf(p['status']),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textOf(p['status']) == '待成交'
                        ? Colors.orange.shade800
                        : textOf(p['status']) == '已成交'
                            ? Colors.green.shade700
                            : textOf(p['status']) == '未聯絡'
                                ? Colors.red.shade700
                                : navy,
                  ),
                ),
              ),
            ),
            followUpStatusCard(
              logs
                  .map((e) => parseAnyDate(e['engaged_on'] ?? e['engaged_at']))
                  .whereType<DateTime>()
                  .fold<DateTime?>(
                    parseAnyDate(p['created_at']),
                    (latest, d) =>
                        latest == null || d.isAfter(latest) ? d : latest,
                  ),
            ),
            FilledButton.icon(
                onPressed: convert,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('轉為成交客戶')),
            const SizedBox(height: 14),
            TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: '搜尋經營紀錄',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder())),
            sectionTitle('經營歷程 ${logs.length} 筆'),
            if (filtered.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(18), child: Text('尚無符合的經營紀錄'))),
            ...filtered.map((e) => Card(
                    child: ListTile(
                  onTap: () => editLog(e),
                  leading: const Icon(Icons.history),
                  title: Text(textOf(e['content'])),
                  subtitle: Text([
                    formatDateOnly(e['engaged_on'] ?? e['engaged_at']),
                    textOf(e['status_note'])
                  ].where((x) => x.isNotEmpty).join('\n')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await editLog(e);
                      } else if (value == 'delete') {
                        await confirmDelete(context, () async {
                          await repo.remove(
                              'engagement_logs', e['id'].toString());
                          await load();
                        });
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('修改')),
                      PopupMenuItem(value: 'delete', child: Text('刪除')),
                    ],
                  ),
                ))),
          ]),
    );
  }
}

class RecruitmentPage extends StatefulWidget {
  const RecruitmentPage({super.key});
  @override
  State<RecruitmentPage> createState() => _RecruitmentPageState();
}

class _RecruitmentPageState extends State<RecruitmentPage>
    with AutomaticKeepAliveClientMixin {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> progressLogs = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final next = await repo.list('recruitments');
      final logs = await repo.list('recruitment_logs');
      if (mounted) {
        setState(() {
          rows = next;
          progressLogs = logs;
        });
      }
    } catch (e) {
      if (mounted) snack(context, '請先執行 005_customer_list_v6_4_migration.sql');
    }
  }

  DateTime? lastProgressFor(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final dates = progressLogs
        .where((e) => e['recruitment_id']?.toString() == id)
        .map((e) => parseAnyDate(e['recruited_on']))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isNotEmpty) return dates.first;
    return parseAnyDate(row['created_at']);
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: textOf(row?['name']));
    final phone = TextEditingController(text: textOf(row?['phone']));
    final lineId = TextEditingController(text: textOf(row?['line_id']));
    final birthday = TextEditingController(text: textOf(row?['birthday']));
    final occupation = TextEditingController(text: textOf(row?['occupation']));
    final company = TextEditingController(text: textOf(row?['company']));
    final family = TextEditingController(text: textOf(row?['family_status']));
    final notes = TextEditingController(text: textOf(row?['notes']));
    String sourceType = textOf(row?['source_type']).isNotEmpty
        ? textOf(row?['source_type'])
        : (textOf(row?['source_customer_id']).isNotEmpty ? '成交客戶' : '自行新增');
    const sourceOptions = [
      '自行新增',
      '成交客戶',
      '情境',
      '朋友',
      '共電',
      '其他',
    ];
    if (!sourceOptions.contains(sourceType)) {
      sourceType = '其他';
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(children: [
          if (row == null)
            addModalHeader(
              context,
              '新增增員名單',
              () => [
                name.text,
                phone.text,
                lineId.text,
                birthday.text,
                occupation.text,
                company.text,
                family.text,
                notes.text
              ].any((e) => e.trim().isNotEmpty),
            )
          else
            const Text('編輯增員資料',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          field(name, '姓名 *'),
          field(phone, '手機'),
          field(lineId, 'LINE ID'),
          field(birthday, '生日（民國YYY-MM-DD）'),
          field(occupation, '職業'),
          field(company, '公司'),
          field(family, '家庭狀況'),
          DropdownButtonFormField<String>(
            initialValue: sourceType,
            decoration: const InputDecoration(
              labelText: '來源',
              border: OutlineInputBorder(),
            ),
            items: sourceOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) sourceType = value;
            },
          ),
          field(notes, '備註', maxLines: 4),
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
              child: const Text('儲存')),
        ])),
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
      'source_type': sourceType,
      'referred_by_name': textOf(row?['source_customer_id']).isNotEmpty &&
              textOf(row?['referred_by_name']).isNotEmpty
          ? textOf(row?['referred_by_name'])
          : sourceType,
      'notes': blank(notes.text),
      'status': row?['status']?.toString() ?? '增員中',
    };
    if (row == null)
      await repo.insert('recruitments', values);
    else
      await repo.update('recruitments', row['id'].toString(), values);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final k = search.text.trim().toLowerCase();
    final filtered = rows
        .where((r) =>
            k.isEmpty ||
            [
              r['name'],
              r['phone'],
              r['occupation'],
              r['company'],
              r['referred_by_name']
            ].whereType<Object>().join(' ').toLowerCase().contains(k))
        .toList()
      ..sort((a, b) {
        final la = followUpLightFor(lastProgressFor(a));
        final lb = followUpLightFor(lastProgressFor(b));
        final byLight = followUpPriority(la).compareTo(followUpPriority(lb));
        if (byLight != 0) return byLight;
        final da = lastProgressFor(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = lastProgressFor(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('增員')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => edit(),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('新增增員')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: const BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
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
            child: filtered.isEmpty
                ? const Center(child: Text('目前沒有增員名單'))
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          return Card(
                              child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RecruitmentDetailPage(
                                          recruitment: row)));
                              await load();
                            },
                            title: Row(children: [
                              followUpDot(
                                  followUpLightFor(lastProgressFor(row)),
                                  size: 10),
                              const SizedBox(width: 7),
                              Expanded(
                                  child: Text(
                                nameWithRocBirthday(
                                    row['name'], row['birthday']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              )),
                            ]),
                            subtitle: Text([
                              textOf(row['phone']),
                              '來源：${textOf(row['referred_by_name']).isNotEmpty ? textOf(row['referred_by_name']) : (textOf(row['source_type']).isNotEmpty ? textOf(row['source_type']) : '自行新增')}',
                            ].where((e) => e.isNotEmpty).join('\n')),
                            trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit')
                                    await edit(row);
                                  else
                                    await confirmDelete(context, () async {
                                      await repo.remove(
                                          'recruitments', row['id'].toString());
                                      await load();
                                    });
                                },
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('編輯')),
                                      PopupMenuItem(
                                          value: 'delete', child: Text('刪除')),
                                    ]),
                          ));
                        }))),
      ]),
    );
  }
}

class RecruitmentDetailPage extends StatefulWidget {
  const RecruitmentDetailPage({super.key, required this.recruitment});
  final Map<String, dynamic> recruitment;
  @override
  State<RecruitmentDetailPage> createState() => _RecruitmentDetailPageState();
}

class _RecruitmentDetailPageState extends State<RecruitmentDetailPage> {
  final repo = Repo();
  final search = TextEditingController();
  List<Map<String, dynamic>> logs = [];
  String get recruitmentId => widget.recruitment['id'].toString();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await repo.recruitmentLogs(recruitmentId);
    if (mounted) setState(() => logs = x);
  }

  Future<void> addLog() async {
    final when = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final status = TextEditingController();
    final content = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(children: [
          addModalHeader(
            context,
            '新增增員紀錄',
            () =>
                status.text.trim().isNotEmpty || content.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 18),
          field(when, '增員日期（YYYY-MM-DD）'),
          field(status, '目前增員狀況'),
          field(content, '增員備註 / 內容 *', maxLines: 5),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('儲存本次紀錄')),
        ])),
      ),
    );
    if (saved != true || content.text.trim().isEmpty) return;
    final date = parseFormDate(when.text);
    if (date == null) {
      if (mounted)
        snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
      return;
    }
    try {
      await repo.insert('recruitment_logs', {
        'recruitment_id': recruitmentId,
        'recruited_on': DateFormat('yyyy-MM-dd').format(date),
        'status_note': blank(status.text),
        'content': content.text.trim(),
      });
      await load();
      if (mounted) snack(context, '增員紀錄已新增');
    } catch (e) {
      if (mounted) snack(context, '增員紀錄儲存失敗：$e');
    }
  }

  Future<void> editLog(Map<String, dynamic> row) async {
    final when =
        TextEditingController(text: formatDateOnly(row['recruited_on']));
    final status = TextEditingController(text: textOf(row['status_note']));
    final content = TextEditingController(text: textOf(row['content']));
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(children: [
          const Text('修改增員紀錄',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          field(when, '增員日期（YYYY-MM-DD）'),
          field(status, '目前增員狀況'),
          field(content, '增員備註 / 內容 *', maxLines: 5),
          FilledButton(
            onPressed: () {
              if (content.text.trim().isEmpty) {
                snack(context, '請輸入增員內容');
                return;
              }
              if (parseFormDate(when.text) == null) {
                snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('儲存修改'),
          ),
        ])),
      ),
    );
    if (saved != true || content.text.trim().isEmpty) return;
    final date = parseFormDate(when.text);
    if (date == null) {
      if (mounted)
        snack(context, '日期格式請輸入 YYYY-MM-DD 或 YYYY/MM/DD 或 YYYY/MM/DD');
      return;
    }
    await repo.update('recruitment_logs', row['id'].toString(), {
      'recruited_on': DateFormat('yyyy-MM-dd').format(date),
      'status_note': blank(status.text),
      'content': content.text.trim(),
    });
    await load();
  }

  Future<void> copyToCustomer() async {
    final r = widget.recruitment;
    final linked = textOf(r['converted_customer_id']);
    if (linked.isNotEmpty) {
      if (mounted) snack(context, '這筆增員已經複製成成交客戶，兩邊資料都保留');
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('增員轉為成交客戶'),
                content: Text(
                    '將「${textOf(r['name'])}」複製到成交客戶？\n增員資料與增員紀錄都會保留，不會移除。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('複製到客戶')),
                ]));
    if (ok != true) return;
    try {
      final c = await repo.insertReturning('customers', {
        'name': textOf(r['name']),
        'phone': r['phone'],
        'line_id': r['line_id'],
        'birthday': r['birthday'],
        'occupation': r['occupation'],
        'company': r['company'],
        'family_status': r['family_status'],
        'notes': r['notes'],
        'closed_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'source_recruitment_id': recruitmentId,
      });
      await repo.update('recruitments', recruitmentId, {
        'converted_customer_id': c['id'].toString(),
      });
      if (mounted) snack(context, '已複製到成交客戶，增員資料仍保留');
    } catch (e) {
      if (mounted) snack(context, '複製到客戶失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recruitment;
    final k = search.text.trim().toLowerCase();
    final filtered = logs
        .where((e) =>
            k.isEmpty ||
            [e['content'], e['status_note'], e['recruited_on']]
                .whereType<Object>()
                .join(' ')
                .toLowerCase()
                .contains(k))
        .toList();

    // 增員歷程顯示排序：日期新到舊，同一天後新增的在上面
    filtered.sort((a, b) {
      final dateA = parseAnyDate(a['recruited_on']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = parseAnyDate(b['recruited_on']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateResult = dateB.compareTo(dateA);
      if (dateResult != 0) return dateResult;

      final createdA = parseAnyDate(a['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final createdB = parseAnyDate(b['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final createdResult = createdB.compareTo(createdA);
      if (createdResult != 0) return createdResult;

      return textOf(b['id']).compareTo(textOf(a['id']));
    });

    return Scaffold(
      appBar: AppBar(title: Text(textOf(r['name']))),
      bottomNavigationBar: mainNavigationBar(context, 4),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: addLog,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('新增增員紀錄')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      infoRow('手機', textOf(r['phone'])),
                      infoRow('LINE', textOf(r['line_id'])),
                      infoRow('生日', formatRocBirthday(r['birthday'])),
                      infoRow('職業', textOf(r['occupation'])),
                      infoRow('公司', textOf(r['company'])),
                      infoRow('家庭', textOf(r['family_status'])),
                      infoRow(
                        '來源',
                        textOf(r['referred_by_name']).isNotEmpty
                            ? textOf(r['referred_by_name'])
                            : (textOf(r['source_type']).isNotEmpty
                                ? textOf(r['source_type'])
                                : (textOf(r['source_customer_id']).isNotEmpty
                                    ? '成交客戶'
                                    : '自行新增')),
                      ),
                      infoRow('備註', textOf(r['notes'])),
                    ]))),
            followUpStatusCard(
              logs
                  .map((e) => parseAnyDate(e['recruited_on']))
                  .whereType<DateTime>()
                  .fold<DateTime?>(
                    parseAnyDate(r['created_at']),
                    (latest, d) =>
                        latest == null || d.isAfter(latest) ? d : latest,
                  ),
            ),
            FilledButton.icon(
                onPressed: copyToCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('增員轉為成交客戶（複製）')),
            const SizedBox(height: 14),
            TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: '搜尋增員紀錄',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder())),
            sectionTitle('增員歷程 ${logs.length} 筆'),
            if (filtered.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(18), child: Text('尚無符合的增員紀錄'))),
            ...filtered.map((e) => Card(
                    child: ListTile(
                  onTap: () => editLog(e),
                  leading: const Icon(Icons.history),
                  title: Text(textOf(e['content'])),
                  subtitle: Text([
                    formatDateOnly(e['recruited_on']),
                    textOf(e['status_note'])
                  ].where((x) => x.isNotEmpty).join('\n')),
                  trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit')
                          await editLog(e);
                        else
                          await confirmDelete(context, () async {
                            await repo.remove(
                                'recruitment_logs', e['id'].toString());
                            await load();
                          });
                      },
                      itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('修改')),
                            PopupMenuItem(value: 'delete', child: Text('刪除')),
                          ]),
                ))),
          ]),
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
                      items: const ['年繳', '半年繳', '季繳', '月繳']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => frequency = v);
                      }),
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
                                items: const ['年繳', '半年繳', '季繳', '月繳']
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
        bottomNavigationBar: mainNavigationBar(context, 1),
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

class ReferralTreePage extends StatefulWidget {
  const ReferralTreePage({super.key, required this.rootCustomer});
  final Map<String, dynamic> rootCustomer;

  @override
  State<ReferralTreePage> createState() => _ReferralTreePageState();
}

class _ReferralTreePageState extends State<ReferralTreePage> {
  final repo = Repo();
  final search = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> contacts = [];
  bool loading = true;
  bool expandAll = false;
  Map<String, dynamic>? displayRoot;
  final Set<String> collapsed = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Map<String, dynamic>? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in customers) {
      if (c['id'].toString() == id) return c;
    }
    return null;
  }

  Map<String, dynamic> findTopAncestor(Map<String, dynamic> start) {
    var current = start;
    final visited = <String>{};
    while (true) {
      final id = current['id'].toString();
      if (!visited.add(id)) return current;
      final parent = byId(textOf(current['referred_by_customer_id']));
      if (parent == null) return current;
      current = parent;
    }
  }

  Future<void> load() async {
    final c = await repo.list('customers');
    final p = await repo.list('contacts');
    if (!mounted) return;

    customers = c;
    contacts = p;
    final requested =
        byId(widget.rootCustomer['id']?.toString()) ?? widget.rootCustomer;

    setState(() {
      displayRoot = findTopAncestor(requested);
      loading = false;
    });
  }

  List<Map<String, dynamic>> referralsOf(String customerId) => contacts
      .where((e) => e['customer_id']?.toString() == customerId)
      .toList();

  List<Map<String, dynamic>> directCustomerChildren(String customerId) =>
      customers
          .where((e) => textOf(e['referred_by_customer_id']) == customerId)
          .toList();

  Map<String, dynamic>? convertedChild(
    Map<String, dynamic> referral,
    String parentId,
  ) {
    final direct = byId(textOf(referral['converted_customer_id']));
    if (direct != null) return direct;

    final contactId = referral['id']?.toString() ?? '';
    for (final c in directCustomerChildren(parentId)) {
      if (textOf(c['source_contact_id']) == contactId) return c;
    }

    // 舊資料補連結：同一推薦來源且姓名相同時視為同一人。
    final name = textOf(referral['name']).trim();
    if (name.isNotEmpty) {
      for (final c in directCustomerChildren(parentId)) {
        if (textOf(c['name']).trim() == name) return c;
      }
    }
    return null;
  }

  int descendantCount(Map<String, dynamic> customer, [Set<String>? seen]) {
    final visited = seen ?? <String>{};
    final id = customer['id'].toString();
    if (!visited.add(id)) return 0;

    var total = 0;
    final linked = <String>{};

    for (final referral in referralsOf(id)) {
      total++;
      final child = convertedChild(referral, id);
      if (child != null) {
        linked.add(child['id'].toString());
        total += descendantCount(child, visited);
      }
    }

    for (final child in directCustomerChildren(id)) {
      if (linked.contains(child['id'].toString())) continue;
      total++;
      total += descendantCount(child, visited);
    }

    return total;
  }

  bool subtreeMatches(Map<String, dynamic> customer, String keyword,
      [Set<String>? seen]) {
    if (keyword.isEmpty) return true;

    final visited = seen ?? <String>{};
    final id = customer['id'].toString();
    if (!visited.add(id)) return false;

    if (textOf(customer['name']).toLowerCase().contains(keyword)) return true;

    for (final referral in referralsOf(id)) {
      if (textOf(referral['name']).toLowerCase().contains(keyword)) return true;
      final child = convertedChild(referral, id);
      if (child != null && subtreeMatches(child, keyword, visited)) return true;
    }

    for (final child in directCustomerChildren(id)) {
      if (subtreeMatches(child, keyword, visited)) return true;
    }
    return false;
  }

  Widget statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget customerNode(
    Map<String, dynamic> customer,
    int depth,
    Set<String> visited, {
    String? relation,
  }) {
    final id = customer['id'].toString();
    if (visited.contains(id) || depth > 40) {
      return const SizedBox.shrink();
    }

    final nextVisited = {...visited, id};
    final referrals = referralsOf(id);
    final directChildren = directCustomerChildren(id);
    final linkedCustomerIds = <String>{};
    final keyword = search.text.trim().toLowerCase();

    final hasChildren = referrals.isNotEmpty || directChildren.isNotEmpty;
    final shouldAutoCollapse =
        !expandAll && keyword.isEmpty && depth >= 2 && hasChildren;
    final isCollapsed = collapsed.contains(id) || shouldAutoCollapse;

    final childWidgets = <Widget>[];

    if (!isCollapsed || keyword.isNotEmpty) {
      for (final referral in referrals) {
        final child = convertedChild(referral, id);

        if (child != null) {
          linkedCustomerIds.add(child['id'].toString());

          if (keyword.isEmpty ||
              subtreeMatches(child, keyword) ||
              textOf(referral['name']).toLowerCase().contains(keyword)) {
            childWidgets.add(
              customerNode(
                child,
                depth + 1,
                nextVisited,
                relation: textOf(referral['category']),
              ),
            );
          }
        } else {
          if (keyword.isNotEmpty &&
              !textOf(referral['name']).toLowerCase().contains(keyword)) {
            continue;
          }

          childWidgets.add(
            _leafReferral(
              referral,
              depth + 1,
            ),
          );
        }
      }

      // 補顯示已是成交客戶，但舊資料 contact 關聯缺漏的節點。
      for (final child in directChildren) {
        if (linkedCustomerIds.contains(child['id'].toString())) continue;
        if (keyword.isNotEmpty && !subtreeMatches(child, keyword)) continue;

        childWidgets.add(
          customerNode(
            child,
            depth + 1,
            nextVisited,
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: depth == 0 ? 0 : 22,
        top: depth == 0 ? 0 : 7,
      ),
      child: Container(
        decoration: depth == 0
            ? null
            : BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                ),
              ),
        padding: EdgeInsets.only(left: depth == 0 ? 0 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: depth == 0 ? const Color(0xFFE8EEF9) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: hasChildren
                    ? () {
                        setState(() {
                          expandAll = false;
                          if (collapsed.contains(id)) {
                            collapsed.remove(id);
                          } else {
                            collapsed.add(id);
                          }
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textOf(customer['name']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (relation != null &&
                                    relation.trim().isNotEmpty)
                                  relation.trim(),
                                '推薦 ${referrals.length} 人',
                                if (hasChildren)
                                  '下層 ${descendantCount(customer)} 人',
                              ].join(' · '),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusBadge('成交客戶', Colors.green),
                      if (hasChildren) ...[
                        const SizedBox(width: 6),
                        Icon(
                          isCollapsed && keyword.isEmpty
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ...childWidgets,
          ],
        ),
      ),
    );
  }

  Widget _leafReferral(Map<String, dynamic> referral, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: 22, top: 7),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textOf(referral['name']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        textOf(referral['category']).isEmpty
                            ? '推薦人脈'
                            : textOf(referral['category']),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                statusBadge(
                  textOf(referral['status']).isEmpty
                      ? '未聯絡'
                      : textOf(referral['status']),
                  textOf(referral['status']) == '已成交'
                      ? Colors.green
                      : textOf(referral['status']) == '待成交'
                          ? Colors.orange
                          : const Color(0xFF315A9B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推薦樹狀圖'),
        actions: [
          IconButton(
            tooltip: expandAll ? '恢復精簡顯示' : '全部展開',
            onPressed: () {
              setState(() {
                expandAll = !expandAll;
                collapsed.clear();
              });
            },
            icon: Icon(
              expandAll ? Icons.unfold_less : Icons.unfold_more,
            ),
          ),
          IconButton(
            tooltip: '重新整理',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : displayRoot == null
              ? const Center(child: Text('找不到推薦關係'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 1000
                        ? 1000.0
                        : constraints.maxWidth;

                    return RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: maxWidth,
                              child: TextField(
                                controller: search,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '搜尋樹狀圖姓名',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: search.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            search.clear();
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: maxWidth,
                              child: customerNode(
                                displayRoot!,
                                0,
                                <String>{},
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

enum FollowUpLight { red, yellow, green }

FollowUpLight customerFollowUpLightFor(DateTime? lastUpdate) {
  if (lastUpdate == null) return FollowUpLight.red;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
  final days = today.difference(d).inDays;
  if (days <= 30) return FollowUpLight.green;
  if (days <= 40) return FollowUpLight.yellow;
  return FollowUpLight.red;
}

String customerFollowUpLabel(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.green:
      return '30天內有聯絡';
    case FollowUpLight.yellow:
      return '31–40天未聯絡';
    case FollowUpLight.red:
      return '41天以上未聯絡';
  }
}

FollowUpLight followUpLightFor(DateTime? lastUpdate) {
  if (lastUpdate == null) return FollowUpLight.red;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
  final days = today.difference(d).inDays;
  if (days <= 15) return FollowUpLight.green;
  if (days <= 25) return FollowUpLight.yellow;
  return FollowUpLight.red;
}

Color followUpColor(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return Colors.red;
    case FollowUpLight.yellow:
      return Colors.amber.shade700;
    case FollowUpLight.green:
      return Colors.green;
  }
}

String followUpLabel(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return '26天以上未更新';
    case FollowUpLight.yellow:
      return '16–25天未更新';
    case FollowUpLight.green:
      return '15天內有進度';
  }
}

int followUpPriority(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return 0;
    case FollowUpLight.yellow:
      return 1;
    case FollowUpLight.green:
      return 2;
  }
}

DateTime? parseAnyDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Widget followUpDot(FollowUpLight light, {double size = 12}) {
  final color = followUpColor(light);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .30),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
  );
}

Widget followUpStatusCard(DateTime? lastUpdate) {
  final light = followUpLightFor(lastUpdate);
  return Card(
    child: ListTile(
      leading: followUpDot(light, size: 16),
      title: Text(
        followUpLabel(light),
        style: TextStyle(
          color: followUpColor(light),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        lastUpdate == null
            ? '尚無進度紀錄'
            : '最近更新：${DateFormat('yyyy-MM-dd').format(lastUpdate)}',
      ),
    ),
  );
}

Future<void> closeAddModal(
  BuildContext context,
  bool Function() hasUnsavedChanges,
) async {
  if (!hasUnsavedChanges()) {
    Navigator.pop(context, false);
    return;
  }

  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('尚未儲存'),
      content: const Text('目前輸入的內容尚未儲存，確定要關閉視窗嗎？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('繼續編輯'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('放棄並關閉'),
        ),
      ],
    ),
  );

  if (discard == true && context.mounted) {
    Navigator.pop(context, false);
  }
}

Widget addModalHeader(
  BuildContext context,
  String title,
  bool Function() hasUnsavedChanges,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      IconButton(
        tooltip: '關閉',
        onPressed: () => closeAddModal(context, hasUnsavedChanges),
        icon: const Icon(Icons.close),
      ),
    ],
  );
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

DateTime? parseFormDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final normalized = value.replaceAll('/', '-').replaceAll('.', '-');

  return DateTime.tryParse(normalized);
}

String formatDateOnly(dynamic raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return '';
  final dt = DateTime.tryParse(value)?.toLocal();
  if (dt == null)
    return value.length >= 10
        ? value.substring(0, 10).replaceAll('-', '/')
        : value;
  return DateFormat('yyyy/MM/dd').format(dt);
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
