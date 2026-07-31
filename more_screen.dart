import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.instance.user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(email), subtitle: const Text('Project 9Grid CRM 使用者'))),
          const SizedBox(height: 12),
          Card(child: Column(children: [const ListTile(leading: Icon(Icons.cloud_done), title: Text('Supabase 雲端同步'), subtitle: Text('已啟用 RLS 個人資料隔離')), const Divider(height: 1), ListTile(leading: const Icon(Icons.logout), title: const Text('登出'), onTap: () => SupabaseService.instance.signOut())])),
          const SizedBox(height: 20),
          const Text('版本 3.0 Sprint 1 Alpha', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
