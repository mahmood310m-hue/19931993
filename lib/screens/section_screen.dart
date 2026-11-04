import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/school_service.dart';

class SectionScreen extends StatefulWidget {
  final String title, table; final bool canEdit;
  const SectionScreen({super.key, required this.title, required this.table, required this.canEdit});
  @override State<SectionScreen> createState() => _SectionScreenState();
}
class _SectionScreenState extends State<SectionScreen> {
  late final service = SchoolService(Supabase.instance.client);
  late Future<List<Map<String,dynamic>>> future;
  @override void initState() { super.initState(); future = service.rows(widget.table); }
  void reload() => setState(() => future = service.rows(widget.table));
  String label(Map<String,dynamic> row) => (row['full_name'] ?? row['title'] ?? row['student_name'] ?? row['name'] ?? 'سجل').toString();
  Future<void> addItem() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text('إضافة إلى ${widget.title}'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'الاسم أو العنوان')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('حفظ'))]));
    if (value == null || value.isEmpty) return;
    final key = ['announcements','news'].contains(widget.table) ? 'title' : 'full_name';
    try { await service.insert(widget.table, {key:value}); reload(); }
    catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e'))); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [
      if(widget.canEdit) IconButton(onPressed: addItem, icon: const Icon(Icons.add))
    ]),
    body: FutureBuilder<List<Map<String,dynamic>>>(future: future, builder: (context, snap) {
      if(snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if(snap.hasError) return Center(child: Text('تعذر تحميل البيانات: ${snap.error}'));
      final rows = snap.data ?? [];
      if(rows.isEmpty) return const Center(child: Text('لا توجد بيانات منشورة حالياً'));
      return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length,
        separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (_,i) => Card(child: ListTile(
          title: Text(label(rows[i])),
          subtitle: Text(rows[i]['class_name']?.toString() ?? rows[i]['description']?.toString() ?? ''),
          trailing: widget.canEdit ? IconButton(icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final id = rows[i]['id']?.toString(); if(id == null) return;
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('تأكيد الحذف'), content: const Text('هل تريد حذف هذا السجل؟'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('إلغاء')),
                  FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('حذف'))]));
              if(ok == true) { try { await service.delete(widget.table,id); reload(); } catch(e) {
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحذف: $e')));
              }}
            }) : null,
        )));
    }),
  );
}
