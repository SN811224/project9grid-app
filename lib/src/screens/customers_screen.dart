import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../repositories/crm_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with AutomaticKeepAliveClientMixin {
  final _repository = CrmRepository();
  final _search = TextEditingController();
  List<Customer> _customers = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repository.fetchCustomers();
    if (!mounted) return;
    setState(() {
      _customers = rows;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final occupation = TextEditingController();
    final company = TextEditingController();
    final premium = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '新增成交客戶',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _field(name, '姓名 *'),
              _field(phone, '手機'),
              _field(occupation, '職業'),
              _field(company, '公司'),
              _field(
                premium,
                '年繳保費',
                keyboardType: TextInputType.number,
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && name.text.trim().isNotEmpty) {
      await _repository.addCustomer(
        name: name.text,
        phone: phone.text,
        occupation: occupation.text,
        company: company.text,
        annualPremium: double.tryParse(premium.text) ?? 0,
      );
      await _load();
    }
  }

  static Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final keyword = _search.text.trim().toLowerCase();
    final filtered = _customers.where((customer) {
      return keyword.isEmpty ||
          customer.name.toLowerCase().contains(keyword) ||
          (customer.phone ?? '').toLowerCase().contains(keyword) ||
          (customer.company ?? '').toLowerCase().contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('成交客戶')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF214D8D),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜尋姓名、手機或公司',
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('尚無成交客戶'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final customer = filtered[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE7EEF9),
                                  child: Text(
                                    customer.name.isEmpty
                                        ? '?'
                                        : customer.name[0],
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    customer.occupation,
                                    customer.company,
                                    customer.phone,
                                  ]
                                      .whereType<String>()
                                      .where((e) => e.isNotEmpty)
                                      .join('・'),
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
