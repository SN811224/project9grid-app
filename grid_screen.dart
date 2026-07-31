import 'package:flutter/material.dart';

class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  static const categories = ['親戚', '同學', '鄰居', '同事', '中心客戶', '前同事', '家人', '朋友', '社團'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('九宮格')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('轉介紹九宮格', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Sprint 2 會讓每位成交客戶擁有自己的可操作九宮格。'),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final center = index == 4;
              return Card(
                color: center ? Theme.of(context).colorScheme.primary : Colors.white,
                child: Center(child: Text(categories[index], textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: center ? Colors.white : null))),
              );
            },
          ),
        ],
      ),
    );
  }
}
