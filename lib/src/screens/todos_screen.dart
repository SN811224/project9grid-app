import 'package:flutter/material.dart';

import '../repositories/crm_repository.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen>
    with AutomaticKeepAliveClientMixin {
  final _repository = CrmRepository();
  List<Map<String, dynamic>> _todos = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repository.fetchTodos();
    if (!mounted) return;
    setState(() => _todos = rows);
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增待辦'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(
            labelText: '待辦事項',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('儲存'),
          ),
        ],
      ),
    );

    if (saved == true && title.text.trim().isNotEmpty) {
      await _repository.addTodo(title.text);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('待辦')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _todos.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 260),
                  Center(child: Text('目前沒有待辦事項')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _todos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text((todo['title'] as String?) ?? ''),
                      subtitle: Text((todo['status'] as String?) ?? '待處理'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
