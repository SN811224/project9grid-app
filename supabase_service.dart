import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';

class SupabaseService {
  SupabaseService._();

  static final instance = SupabaseService._();
  SupabaseClient get client => Supabase.instance.client;
  User? get user => client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  Stream<List<Customer>> watchCustomers() {
    final uid = user?.id;
    if (uid == null) return const Stream.empty();

    return client
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Customer.fromMap).toList());
  }

  Future<void> addCustomer(Map<String, dynamic> values) async {
    final uid = user?.id;
    if (uid == null) throw StateError('尚未登入');
    await client.from('customers').insert({...values, 'user_id': uid});
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> values) async {
    await client.from('customers').update(values).eq('id', id);
  }

  Future<void> deleteCustomer(String id) async {
    await client.from('customers').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchDashboard() async {
    final uid = user?.id;
    if (uid == null) return [];
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day + 1).toIso8601String();

    final customers = await client.from('customers').select('id,annual_premium');
    final contacts = await client.from('contacts').select('id,status,next_follow_up_date');
    final todos = await client
        .from('todos')
        .select('id')
        .eq('user_id', uid)
        .gte('due_at', start)
        .lt('due_at', end)
        .neq('status', '已完成');

    final premium = customers.fold<double>(
      0,
      (sum, row) => sum + ((row['annual_premium'] as num?)?.toDouble() ?? 0),
    );
    final dealCount = contacts.where((row) => row['status'] == '已成交').length;
    final followCount = contacts.where((row) {
      final date = DateTime.tryParse(row['next_follow_up_date'] as String? ?? '');
      return date != null && !date.isAfter(today) && row['status'] != '已成交';
    }).length;

    return [
      {'label': '成交客戶', 'value': customers.length.toString()},
      {'label': '今日待辦', 'value': todos.length.toString()},
      {'label': '待追蹤', 'value': followCount.toString()},
      {'label': '人脈成交', 'value': dealCount.toString()},
      {'label': '年繳保費', 'value': premium.toStringAsFixed(0)},
    ];
  }
}
