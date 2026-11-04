import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'section_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override Widget build(BuildContext context) {
    final items = [
      ('إدارة الطلبة','students'),('المتفوقون','top_students'),('الدرجات','grades'),
      ('الحضور والغياب','attendance'),('الإعلانات','announcements'),('الأخبار المتحركة','news'),
      ('الصفوف','classes'),('المواد','subjects'),('إعدادات المدرسة','school_settings'),
    ];
    return Scaffold(appBar: AppBar(title: const Text('لوحة الإدارة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: const ListTile(leading: Icon(Icons.verified_user, color: Color(0xFF579B83)),
          title: Text('وصول إداري محمي'), subtitle: Text('تتحقق صلاحيات الإدارة من قاعدة البيانات عبر RLS.'))),
        const SizedBox(height: 12),
        ...items.map((item) => Card(child: ListTile(
          leading: const Icon(Icons.folder_open, color: Color(0xFF579B83)),
          title: Text(item.$1), trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SectionScreen(title: item.$1, table: item.$2, canEdit: true))),
        ))),
      ]));
  }
}
