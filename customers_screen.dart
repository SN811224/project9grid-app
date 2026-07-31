import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../services/supabase_service.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成交客戶')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerFormScreen())),
        icon: const Icon(Icons.person_add),
        label: const Text('新增客戶'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '搜尋姓名、電話、公司'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: SupabaseService.instance.watchCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('讀取失敗：${snapshot.error}'));
                final customers = (snapshot.data ?? []).where((c) {
                  final haystack = '${c.name} ${c.phone ?? ''} ${c.company ?? ''}'.toLowerCase();
                  return haystack.contains(query);
                }).toList();
                if (customers.isEmpty) return const Center(child: Text('尚無客戶，請按「新增客戶」。'));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: c))),
                        leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name.substring(0, 1))),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${c.occupation ?? '未填職業'}${c.company == null ? '' : '・${c.company}'}\n年繳 NT\$${NumberFormat('#,##0').format(c.annualPremium)}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') await _delete(c);
                          },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('刪除'))],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Customer customer) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('刪除客戶'), content: Text('確定刪除「${customer.name}」及其相關資料？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除'))]));
    if (ok == true) await SupabaseService.instance.deleteCustomer(customer.id);
  }
}
