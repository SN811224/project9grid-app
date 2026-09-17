import 'package:flutter/material.dart';
import '../../core/utils/text_utils.dart';
import '../../core/data/repo.dart';

class ReferralTreePage extends StatefulWidget {
  const ReferralTreePage({super.key, required this.rootCustomer});
  final Map<String, dynamic> rootCustomer;

  @override
  State<ReferralTreePage> createState() => _ReferralTreePageState();
}

class _ReferralTreePageState extends State<ReferralTreePage> {
  final repo = Repo();
  final search = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> contacts = [];
  bool loading = true;
  bool expandAll = false;
  Map<String, dynamic>? displayRoot;
  final Set<String> collapsed = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Map<String, dynamic>? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in customers) {
      if (c['id'].toString() == id) return c;
    }
    return null;
  }

  Map<String, dynamic> findTopAncestor(Map<String, dynamic> start) {
    var current = start;
    final visited = <String>{};
    while (true) {
      final id = current['id'].toString();
      if (!visited.add(id)) return current;
      final parent = byId(textOf(current['referred_by_customer_id']));
      if (parent == null) return current;
      current = parent;
    }
  }

  Future<void> load() async {
    final c = await repo.list('customers');
    final p = await repo.list('contacts');
    if (!mounted) return;

    customers = c;
    contacts = p;
    final requested =
        byId(widget.rootCustomer['id']?.toString()) ?? widget.rootCustomer;

    setState(() {
      displayRoot = findTopAncestor(requested);
      loading = false;
    });
  }

  List<Map<String, dynamic>> referralsOf(String customerId) => contacts
      .where((e) => e['customer_id']?.toString() == customerId)
      .toList();

  List<Map<String, dynamic>> directCustomerChildren(String customerId) =>
      customers
          .where((e) => textOf(e['referred_by_customer_id']) == customerId)
          .toList();

  Map<String, dynamic>? convertedChild(
    Map<String, dynamic> referral,
    String parentId,
  ) {
    final direct = byId(textOf(referral['converted_customer_id']));
    if (direct != null) return direct;

    final contactId = referral['id']?.toString() ?? '';
    for (final c in directCustomerChildren(parentId)) {
      if (textOf(c['source_contact_id']) == contactId) return c;
    }

    // 舊資料補連結：同一推薦來源且姓名相同時視為同一人。
    final name = textOf(referral['name']).trim();
    if (name.isNotEmpty) {
      for (final c in directCustomerChildren(parentId)) {
        if (textOf(c['name']).trim() == name) return c;
      }
    }
    return null;
  }

  int descendantCount(Map<String, dynamic> customer, [Set<String>? seen]) {
    final visited = seen ?? <String>{};
    final id = customer['id'].toString();
    if (!visited.add(id)) return 0;

    var total = 0;
    final linked = <String>{};

    for (final referral in referralsOf(id)) {
      total++;
      final child = convertedChild(referral, id);
      if (child != null) {
        linked.add(child['id'].toString());
        total += descendantCount(child, visited);
      }
    }

    for (final child in directCustomerChildren(id)) {
      if (linked.contains(child['id'].toString())) continue;
      total++;
      total += descendantCount(child, visited);
    }

    return total;
  }

  bool subtreeMatches(Map<String, dynamic> customer, String keyword,
      [Set<String>? seen]) {
    if (keyword.isEmpty) return true;

    final visited = seen ?? <String>{};
    final id = customer['id'].toString();
    if (!visited.add(id)) return false;

    if (textOf(customer['name']).toLowerCase().contains(keyword)) return true;

    for (final referral in referralsOf(id)) {
      if (textOf(referral['name']).toLowerCase().contains(keyword)) return true;
      final child = convertedChild(referral, id);
      if (child != null && subtreeMatches(child, keyword, visited)) return true;
    }

    for (final child in directCustomerChildren(id)) {
      if (subtreeMatches(child, keyword, visited)) return true;
    }
    return false;
  }

  Widget statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget customerNode(
    Map<String, dynamic> customer,
    int depth,
    Set<String> visited, {
    String? relation,
  }) {
    final id = customer['id'].toString();
    if (visited.contains(id) || depth > 40) {
      return const SizedBox.shrink();
    }

    final nextVisited = {...visited, id};
    final referrals = referralsOf(id);
    final directChildren = directCustomerChildren(id);
    final linkedCustomerIds = <String>{};
    final keyword = search.text.trim().toLowerCase();

    final hasChildren = referrals.isNotEmpty || directChildren.isNotEmpty;
    final shouldAutoCollapse =
        !expandAll && keyword.isEmpty && depth >= 2 && hasChildren;
    final isCollapsed = collapsed.contains(id) || shouldAutoCollapse;

    final childWidgets = <Widget>[];

    if (!isCollapsed || keyword.isNotEmpty) {
      for (final referral in referrals) {
        final child = convertedChild(referral, id);

        if (child != null) {
          linkedCustomerIds.add(child['id'].toString());

          if (keyword.isEmpty ||
              subtreeMatches(child, keyword) ||
              textOf(referral['name']).toLowerCase().contains(keyword)) {
            childWidgets.add(
              customerNode(
                child,
                depth + 1,
                nextVisited,
                relation: textOf(referral['category']),
              ),
            );
          }
        } else {
          if (keyword.isNotEmpty &&
              !textOf(referral['name']).toLowerCase().contains(keyword)) {
            continue;
          }

          childWidgets.add(
            _leafReferral(
              referral,
              depth + 1,
            ),
          );
        }
      }

      // 補顯示已是成交客戶，但舊資料 contact 關聯缺漏的節點。
      for (final child in directChildren) {
        if (linkedCustomerIds.contains(child['id'].toString())) continue;
        if (keyword.isNotEmpty && !subtreeMatches(child, keyword)) continue;

        childWidgets.add(
          customerNode(
            child,
            depth + 1,
            nextVisited,
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: depth == 0 ? 0 : 22,
        top: depth == 0 ? 0 : 7,
      ),
      child: Container(
        decoration: depth == 0
            ? null
            : BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                ),
              ),
        padding: EdgeInsets.only(left: depth == 0 ? 0 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: depth == 0 ? const Color(0xFFE8EEF9) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: hasChildren
                    ? () {
                        setState(() {
                          expandAll = false;
                          if (collapsed.contains(id)) {
                            collapsed.remove(id);
                          } else {
                            collapsed.add(id);
                          }
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textOf(customer['name']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (relation != null &&
                                    relation.trim().isNotEmpty)
                                  relation.trim(),
                                '推薦 ${referrals.length} 人',
                                if (hasChildren)
                                  '下層 ${descendantCount(customer)} 人',
                              ].join(' · '),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusBadge('成交客戶', Colors.green),
                      if (hasChildren) ...[
                        const SizedBox(width: 6),
                        Icon(
                          isCollapsed && keyword.isEmpty
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ...childWidgets,
          ],
        ),
      ),
    );
  }

  Widget _leafReferral(Map<String, dynamic> referral, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: 22, top: 7),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textOf(referral['name']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        textOf(referral['category']).isEmpty
                            ? '推薦人脈'
                            : textOf(referral['category']),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                statusBadge(
                  textOf(referral['status']).isEmpty
                      ? '未聯絡'
                      : textOf(referral['status']),
                  textOf(referral['status']) == '已成交'
                      ? Colors.green
                      : textOf(referral['status']) == '待成交'
                          ? Colors.orange
                          : const Color(0xFF315A9B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推薦樹狀圖'),
        actions: [
          IconButton(
            tooltip: expandAll ? '恢復精簡顯示' : '全部展開',
            onPressed: () {
              setState(() {
                expandAll = !expandAll;
                collapsed.clear();
              });
            },
            icon: Icon(
              expandAll ? Icons.unfold_less : Icons.unfold_more,
            ),
          ),
          IconButton(
            tooltip: '重新整理',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : displayRoot == null
              ? const Center(child: Text('找不到推薦關係'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 1000
                        ? 1000.0
                        : constraints.maxWidth;

                    return RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: maxWidth,
                              child: TextField(
                                controller: search,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '搜尋樹狀圖姓名',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: search.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            search.clear();
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: maxWidth,
                              child: customerNode(
                                displayRoot!,
                                0,
                                <String>{},
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
