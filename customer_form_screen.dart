import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/supabase_service.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});
  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController lineId;
  late final TextEditingController occupation;
  late final TextEditingController company;
  late final TextEditingController family;
  late final TextEditingController premium;
  late final TextEditingController notes;
  DateTime? birthday;
  DateTime? closedDate;
  int priority = 3;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    name = TextEditingController(text: c?.name);
    phone = TextEditingController(text: c?.phone);
    lineId = TextEditingController(text: c?.lineId);
    occupation = TextEditingController(text: c?.occupation);
    company = TextEditingController(text: c?.company);
    family = TextEditingController(text: c?.familyStatus);
    premium = TextEditingController(text: c == null ? '' : c.annualPremium.toStringAsFixed(0));
    notes = TextEditingController(text: c?.notes);
    birthday = c?.birthday;
    closedDate = c?.closedDate;
    priority = c?.priority ?? 3;
  }

  @override
  void dispose() {
    for (final c in [name, phone, lineId, occupation, company, family, premium, notes]) { c.dispose(); }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final values = <String, dynamic>{
      'name': name.text.trim(),
      'phone': _emptyToNull(phone.text),
      'line_id': _emptyToNull(lineId.text),
      'occupation': _emptyToNull(occupation.text),
      'company': _emptyToNull(company.text),
      'family_status': _emptyToNull(family.text),
      'annual_premium': double.tryParse(premium.text.replaceAll(',', '')) ?? 0,
      'birthday': birthday?.toIso8601String().substring(0, 10),
      'closed_date': closedDate?.toIso8601String().substring(0, 10),
      'priority': priority,
      'notes': _emptyToNull(notes.text),
    };
    try {
      if (widget.customer == null) {
        await SupabaseService.instance.addCustomer(values);
      } else {
        await SupabaseService.instance.updateCustomer(widget.customer!.id, values);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗：$error')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer == null ? '新增客戶' : '編輯客戶')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: '姓名 *'), validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入姓名' : null),
            const SizedBox(height: 12),
            TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: '電話')),
            const SizedBox(height: 12),
            TextFormField(controller: lineId, decoration: const InputDecoration(labelText: 'LINE ID')),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextFormField(controller: occupation, decoration: const InputDecoration(labelText: '職業'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: company, decoration: const InputDecoration(labelText: '公司')))]),
            const SizedBox(height: 12),
            TextFormField(controller: family, decoration: const InputDecoration(labelText: '家庭狀況')),
            const SizedBox(height: 12),
            TextFormField(controller: premium, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '年繳保費')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(value: priority, decoration: const InputDecoration(labelText: '客戶優先度'), items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${'★' * (i + 1)}${'☆' * (4 - i)}'))), onChanged: (v) => setState(() => priority = v ?? 3)),
            const SizedBox(height: 12),
            _DateTile(label: '生日', value: birthday, onTap: () async { final d = await showDatePicker(context: context, initialDate: birthday ?? DateTime(1990), firstDate: DateTime(1930), lastDate: DateTime.now()); if (d != null) setState(() => birthday = d); }),
            const SizedBox(height: 12),
            _DateTile(label: '成交日期', value: closedDate, onTap: () async { final d = await showDatePicker(context: context, initialDate: closedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setState(() => closedDate = d); }),
            const SizedBox(height: 12),
            TextFormField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: '備註')),
            const SizedBox(height: 20),
            FilledButton(onPressed: saving ? null : save, child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(saving ? '儲存中…' : '儲存客戶'))),
          ],
        ),
      ),
    );
  }

  String? _emptyToNull(String text) => text.trim().isEmpty ? null : text.trim();
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outline)), title: Text(label), subtitle: Text(value == null ? '未設定' : '${value!.year}/${value!.month.toString().padLeft(2, '0')}/${value!.day.toString().padLeft(2, '0')}'), trailing: const Icon(Icons.calendar_month), onTap: onTap);
  }
}
