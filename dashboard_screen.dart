import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Map<String, dynamic>>> metrics;

  @override
  void initState() {
    super.initState();
    metrics = SupabaseService.instance.fetchDashboard();
  }

  void reload() => setState(() => metrics = SupabaseService.instance.fetchDashboard());

  @override
  Widget build(BuildContext context) {
    final name = SupabaseService.instance.user?.email?.split('@').first ?? '顧問';
    return Scaffold(
      appBar: AppBar(title: const Text('CRM 戰情室'), actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$name，${_greeting()}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(DateFormat('yyyy年M月d日 EEEE', 'zh_TW').format(DateTime.now())),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: metrics,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Text('讀取統計失敗：${snapshot.error}');
                final rows = snapshot.data ?? [];
                final icons = [Icons.people, Icons.task_alt, Icons.phone_in_talk, Icons.handshake, Icons.payments];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.35, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => MetricCard(label: rows[index]['label'] as String, value: rows[index]['value'] as String, icon: icons[index]),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('今日重點', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Card(child: ListTile(leading: Icon(Icons.lightbulb_outline), title: Text('先完成到期追蹤，再開發新的九宮格人脈。'), subtitle: Text('Sprint 2 將加入完整待辦清單與生日提醒。'))),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早安';
    if (hour < 18) return '午安';
    return '晚安';
  }
}
