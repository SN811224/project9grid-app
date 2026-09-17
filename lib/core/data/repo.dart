import 'package:supabase_flutter/supabase_flutter.dart';

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
