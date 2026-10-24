import 'package:flutter/material.dart';

import 'gift_repository.dart';

class GiftDeliveryProgressPage extends StatefulWidget {
  const GiftDeliveryProgressPage({
    super.key,
    required this.personType,
    required this.title,
  });

  final String personType;
  final String title;

  @override
  State<GiftDeliveryProgressPage> createState() =>
      _GiftDeliveryProgressPageState();
}

class _GiftDeliveryProgressPageState extends State<GiftDeliveryProgressPage> {
  final GiftRepository repo = GiftRepository();

  bool loading = true;
  String? error;

  List<Map<String, dynamic>> people = [];
  Map<String, GiftDeliveryRecord> records = {};

  bool get isCustomer => widget.personType == 'customer';

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
      final loadedPeople = isCustomer
          ? await repo.customerGiftRecipients()
          : await repo.prospectGiftRecipients();

      final loadedRecords = await repo.giftDeliveryMap(widget.personType);

      if (!mounted) return;

      setState(() {
        people = loadedPeople;
        records = loadedRecords;
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

  bool delivered(String personId) {
    return records[personId]?.delivered == true;
  }

  int get deliveredCount {
    return people.where((person) {
      final id = person['person_id']?.toString() ?? '';
      return delivered(id);
    }).length;
  }

  Future<void> toggleDelivered(
    Map<String, dynamic> person,
    bool value,
  ) async {
    final id = person['person_id']?.toString() ?? '';
    if (id.isEmpty) return;

    // 先立即更新畫面，不等待網路回傳。
    final previous = records[id];

    setState(() {
      records[id] = GiftDeliveryRecord(
        personType: widget.personType,
        personId: id,
        delivered: value,
        deliveredAt: value ? DateTime.now() : null,
      );
    });

    try {
      await repo.setGiftDelivered(
        personType: widget.personType,
        personId: id,
        delivered: value,
      );
    } catch (e) {
      // 儲存失敗才還原原本狀態。
      if (!mounted) return;

      setState(() {
        if (previous == null) {
          records.remove(id);
        } else {
          records[id] = previous;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('儲存失敗：$e')),
      );
    }
  }

  Future<void> resetProgress() async {
    if (people.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重設送禮進度'),
          content: Text(
            '確定要清除「${widget.title}」目前所有已送禮勾選嗎？\n\n'
            '客戶與經營資料不會被刪除。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('全部清除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await repo.resetGiftDeliveries(widget.personType);
      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重設本次送禮進度')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重設失敗：$e')),
      );
    }
  }

  Widget statusBadge(Map<String, dynamic> person) {
    final label = isCustomer
        ? (person['tier_name']?.toString() ?? '')
        : (person['status']?.toString() ?? '經營中');

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = people.length;
    final done = deliveredCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: resetProgress,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text(
              '重設',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '送禮進度',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已送 $done / $total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('資料讀取失敗\n$error'),
                ),
              )
            else if (people.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '目前沒有送禮名單',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              )
            else
              ...people.map((person) {
                final id = person['person_id']?.toString() ?? '';
                final name = person['name']?.toString() ?? '未命名';
                final isDelivered = delivered(id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isDelivered,
                    onChanged: (value) {
                      if (value == null) return;
                      toggleDelivered(person, value);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              decoration: isDelivered
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        statusBadge(person),
                      ],
                    ),
                    subtitle: isDelivered
                        ? const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('已完成送禮'),
                          )
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
