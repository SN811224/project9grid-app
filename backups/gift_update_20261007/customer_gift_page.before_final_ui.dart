import 'package:flutter/material.dart';

import 'gift_delivery_progress_page.dart';
import 'gift_repository.dart';

class CustomerGiftPage extends StatefulWidget {
  const CustomerGiftPage({super.key});

  @override
  State<CustomerGiftPage> createState() => _CustomerGiftPageState();
}

class _CustomerGiftPageState extends State<CustomerGiftPage> {
  final GiftRepository repo = GiftRepository();

  String selectedFilter = '送禮進度';
  bool loading = true;
  String? error;
  List<FamilyGiftSummary> families = [];

  static const filters = [
    '送禮進度',
    '黑鑽級',
    '白金級',
    '金級',
    '銀級',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await repo.familySummaries();

      if (!mounted) return;

      setState(() {
        families = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<FamilyGiftSummary> get filteredFamilies {
    if (selectedFilter == '送禮進度') return families;

    return families
        .where((family) => family.tierName == selectedFilter)
        .toList();
  }

  Widget tierBadge(String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EBFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget familyCard(FamilyGiftSummary family) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    family.familyName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                tierBadge(family.tierName),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '家庭成員：${family.memberCount} 人',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(family.memberNames.join('、')),
            const SizedBox(height: 6),
            Text('主要收禮人：${family.primaryRecipient}'),
            const SizedBox(height: 6),
            const Text(
              '本次送禮：1 份',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedFilter == '送禮進度') {
      return const GiftDeliveryProgressPage(
        personType: 'customer',
        title: '客戶送禮進度',
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '客戶送禮',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selectedFilter == filter,
                      onSelected: (_) {
                        if (filter == '送禮進度') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const GiftDeliveryProgressPage(
                                personType: 'customer',
                                title: '客戶送禮進度',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('資料讀取失敗\n$error'),
                ),
              )
            else if (filteredFamilies.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('目前沒有此等級家庭'),
                  ),
                ),
              )
            else
              ...filteredFamilies.map(familyCard),
          ],
        ),
      ),
    );
  }
}
