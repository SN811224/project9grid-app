import 'package:flutter/material.dart';

Future<void> closeAddModal(
  BuildContext context,
  bool Function() hasUnsavedChanges,
) async {
  if (!hasUnsavedChanges()) {
    Navigator.pop(context, false);
    return;
  }

  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('尚未儲存'),
      content: const Text('目前輸入的內容尚未儲存，確定要關閉視窗嗎？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('繼續編輯'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('放棄並關閉'),
        ),
      ],
    ),
  );

  if (discard == true && context.mounted) {
    Navigator.pop(context, false);
  }
}

Widget addModalHeader(
  BuildContext context,
  String title,
  bool Function() hasUnsavedChanges,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      IconButton(
        tooltip: '關閉',
        onPressed: () => closeAddModal(context, hasUnsavedChanges),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6E788D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? '未填寫' : value)),
      ],
    ),
  );
}

Future<void> confirmDelete(
  BuildContext context,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('確認刪除'),
      content: const Text('刪除後無法復原，確定繼續嗎？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('刪除'),
        ),
      ],
    ),
  );
  if (confirmed == true) await action();
}
