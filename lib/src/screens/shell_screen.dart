import 'package:flutter/material.dart';

import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'grid_screen.dart';
import 'policies_screen.dart';
import 'todos_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    GridScreen(),
    TodosScreen(),
    PoliciesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首頁'),
          NavigationDestination(icon: Icon(Icons.people), label: '客戶'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: '九宮格'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: '待辦'),
          NavigationDestination(icon: Icon(Icons.description), label: '保單'),
        ],
      ),
    );
  }
}
