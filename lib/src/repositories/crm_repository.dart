import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';

class CrmRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('尚未登入');
    return id;
  }

  Future<List<Customer>> fetchCustomers() async {
    final rows = await _client
        .from('customers')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Customer.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCustomer({
    required String name,
    String? phone,
    String? occupation,
    String? company,
    double annualPremium = 0,
  }) async {
    await _client.from('customers').insert({
      'user_id': _userId,
      'name': name.trim(),
      'phone': _blank(phone),
      'occupation': _blank(occupation),
      'company': _blank(company),
      'annual_premium': annualPremium,
      'closed_date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  Future<Map<String, int>> fetchCounts() async {
    final customers = await _client
        .from('customers')
        .select('id')
        .eq('user_id', _userId);

    final contacts = await _client
        .from('contacts')
        .select('id,status')
        .eq('user_id', _userId);

    final todos = await _client
        .from('todos')
        .select('id,status')
        .eq('user_id', _userId);

    final contactRows = contacts as List;
    final todoRows = todos as List;

    return {
      'customers': (customers as List).length,
      'contacts': contactRows.length,
      'todos': todoRows
          .where((row) => (row as Map)['status'] != '已完成')
          .length,
      'converted': contactRows
          .where((row) => (row as Map)['status'] == '已成交')
          .length,
    };
  }

  Future<List<Map<String, dynamic>>> fetchContacts() async {
    final rows = await _client
        .from('contacts')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    final rows = await _client
        .from('todos')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addTodo(String title) async {
    await _client.from('todos').insert({
      'user_id': _userId,
      'title': title.trim(),
      'status': '待處理',
    });
  }

  Future<List<Map<String, dynamic>>> fetchPolicies() async {
    final rows = await _client
        .from('policies')
        .select('*, customers(name)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static String? _blank(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
