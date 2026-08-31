import 'package:flutter/material.dart';

import '../repositories/crm_repository.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen>
    with AutomaticKeepAliveClientMixin {
  final _repository = CrmRepository();
  List<Map<String, dynamic>> _policies = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repository.fetchPolicies();
    if (!mounted) return;
    setState(() => _policies = rows);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('保單管理')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _policies.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 260),
                  Center(child: Text('尚無保單資料')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _policies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final policy = _policies[index];
                  final customer =
                      (policy['customers'] as Map<String, dynamic>?)?['name'] ??
                          '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.description),
                      ),
                      title: Text(
                        (policy['product_name'] as String?) ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '$customer・${policy['policy_type'] ?? ''}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
