import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'gift_repository.dart';

class GiftManagementPage extends StatefulWidget {
  const GiftManagementPage({super.key});

  @override
  State<GiftManagementPage> createState() => _GiftManagementPageState();
}

class _GiftManagementPageState extends State<GiftManagementPage> {
  final GiftRepository repo = GiftRepository();

  final NumberFormat currency = NumberFormat.decimalPattern('zh_TW');

  String selectedFilter = '全部';

  bool loading = true;

  String? error;

  List<FamilyGiftSummary> families = [];

  static const filters = [
    '全部',
    '黑鑽級',
    '白金級',
    '金級',
    '銀級',
    '躉繳客戶',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final result = await repo.familySummaries();

      if (!mounted) return;

      setState(() {
        families = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<FamilyGiftSummary> get filteredFamilies {
    if (selectedFilter == '全部') {
      return families;
    }

    if (selectedFilter == '躉繳客戶') {
      return families.where((e) => e.lumpSumTotal > 0).toList();
    }

    return families.where((e) => e.tierName == selectedFilter).toList();
  }

  Future<void> openFamilyEditor({
    FamilyGiftSummary? family,
  }) async {
    try {
      final customers = await repo.customers();

      final assigned = await repo.assignedCustomerIds(
        excludingFamilyId: family?.familyId,
      );

      if (!mounted) return;

      final available = customers
          .where(
            (customer) => !assigned.contains(
              customer['id']?.toString(),
            ),
          )
          .toList();

      final familyNameController = TextEditingController(
        text: family?.familyName ?? '',
      );

      final searchController = TextEditingController();

      final selectedIds = <String>{...?family?.memberIds};

      String? primaryId = family?.primaryCustomerId;

      String searchText = '';

      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final visibleCustomers = available.where(
                (customer) {
                  final name = customer['name']?.toString().toLowerCase() ?? '';

                  return searchText.isEmpty ||
                      name.contains(
                        searchText.toLowerCase(),
                      );
                },
              ).toList();

              final selectedCustomers = available
                  .where(
                    (customer) => selectedIds.contains(
                      customer['id']?.toString(),
                    ),
                  )
                  .toList();

              return AlertDialog(
                title: Text(
                  family == null ? '建立家庭' : '修改家庭',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: SizedBox(
                  width: 540,
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      TextField(
                        controller: familyNameController,
                        decoration: const InputDecoration(
                          labelText: '家庭名稱',
                          hintText: '例如：王聖恩家庭',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: '搜尋客戶',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            searchText = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '家庭成員',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          itemCount: visibleCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = visibleCustomers[index];

                            final id = customer['id'].toString();

                            final name = customer['name']?.toString() ?? '未命名';

                            return CheckboxListTile(
                              value: selectedIds.contains(
                                id,
                              ),
                              title: Text(name),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedIds.add(id);

                                    primaryId ??= id;
                                  } else {
                                    selectedIds.remove(id);

                                    if (primaryId == id) {
                                      primaryId = selectedIds.isEmpty
                                          ? null
                                          : selectedIds.first;
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      if (selectedCustomers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$primaryId-${selectedIds.length}',
                          ),
                          initialValue: selectedIds.contains(primaryId)
                              ? primaryId
                              : selectedIds.first,
                          decoration: const InputDecoration(
                            labelText: '主要收禮人',
                            border: OutlineInputBorder(),
                          ),
                          items: selectedCustomers
                              .map(
                                (customer) => DropdownMenuItem<String>(
                                  value: customer['id'].toString(),
                                  child: Text(
                                    customer['name']?.toString() ?? '未命名',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              primaryId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      false,
                    ),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (familyNameController.text.trim().isEmpty ||
                          selectedIds.isEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '請輸入家庭名稱並選擇家庭成員',
                            ),
                          ),
                        );

                        return;
                      }

                      primaryId ??= selectedIds.first;

                      await repo.saveFamily(
                        familyId: family?.familyId,
                        familyName: familyNameController.text,
                        customerIds: selectedIds.toList(),
                        primaryCustomerId: primaryId!,
                        giftQuantity: family?.giftQuantity ?? 1,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    },
                    child: Text(
                      family == null ? '建立家庭' : '儲存修改',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      familyNameController.dispose();
      searchController.dispose();

      if (saved == true) {
        await load();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '家庭資料儲存失敗：$e',
          ),
        ),
      );
    }
  }

  Widget familyCard(
    FamilyGiftSummary family,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(
                    family.tierName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  tooltip: '修改家庭',
                  onPressed: () {
                    openFamilyEditor(family: family);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '有效年繳：\$${currency.format(family.annualPremium)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '躉繳累計：\$${currency.format(family.lumpSumTotal)}',
            ),
            const SizedBox(height: 6),
            Text(
              '家庭成員：${family.memberCount} 人',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              family.memberNames.join('、'),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '主要收禮人：${family.primaryRecipient}',
            ),
            const SizedBox(height: 6),
            Text(
              '本次送禮：${family.giftQuantity} 份',
              style: const TextStyle(
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
    final visibleFamilies = filteredFamilies;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '送禮管理',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '重新整理',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openFamilyEditor(),
        icon: const Icon(Icons.add),
        label: const Text('建立家庭'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            100,
          ),
          children: [
            const Text(
              '家庭送禮',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '依家庭有效年繳保費自動分級',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map(
                  (filter) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: selectedFilter == filter,
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 60,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '資料讀取失敗\n$error',
                  ),
                ),
              )
            else if (visibleFamilies.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        families.isEmpty ? '尚未建立家庭資料' : '此分類目前沒有家庭',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...visibleFamilies.map(
                familyCard,
              ),
          ],
        ),
      ),
    );
  }
}
