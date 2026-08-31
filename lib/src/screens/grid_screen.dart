import 'package:flutter/material.dart';

import '../repositories/crm_repository.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen>
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

  final _repository = CrmRepository();
  List<Map<String, dynamic>> _contacts = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repository.fetchContacts();
    if (!mounted) return;
    setState(() => _contacts = rows);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('九宮格')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index == 4) {
              return const Card(
                color: Color(0xFF214D8D),
                child: Center(
                  child: Text(
                    '成交客戶',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }

            final categoryIndex = index < 4 ? index : index - 1;
            final category = categories[categoryIndex];
            final count = _contacts
                .where((contact) => contact['category'] == category)
                .length;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text('$count 人'),
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
