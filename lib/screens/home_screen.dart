import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/school_service.dart';
import 'section_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  late final SchoolService service = SchoolService(Supabase.instance.client);
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> news = [];
  Timer? timer;
  DateTime now = DateTime.now();
  bool paused = false;
  @override
  void initState() { super.initState(); load(); timer = Timer.periodic(const Duration(seconds: 1), (_) { if(mounted) setState(() => now = DateTime.now()); }); }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  Future<void> load() async {
    try {
      final p = await service.profile();
      final n = await service.rows('news');
      if (mounted) setState(() { profile = p; news = n; });
    } catch (_) { if(mounted) setState(() => profile = null); }
  }
  Future<int> safeCount(String t) async { try { return await service.count(t); } catch (_) { return 0; } }

  @override
  Widget build(BuildContext context) {
    final role = profile?['role']?.toString() ?? 'student';
    final isAdmin = role == 'admin' || role == 'super_admin';
    final sections = [
      ('المتفوقون', Icons.emoji_events_outlined, 'top_students'),
      ('الدرجات', Icons.grade_outlined, 'grades'),
      ('الحضور والغياب', Icons.fact_check_outlined, 'attendance'),
      ('الإعلانات', Icons.campaign_outlined, 'announcements'),
      ('الطلبة', Icons.people_outline, 'students'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدرسة كوثر الأهلية المختلطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('hh:mm:ss a', 'en').format(now), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('yyyy/MM/dd', 'en').format(now), style: const TextStyle(fontSize: 10)),
            ])),
          IconButton(tooltip: 'تسجيل الخروج', onPressed: () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE4F4ED), Color(0xFFF2FAF6)]),
              borderRadius: BorderRadius.circular(24)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مدرسة كوثر: بيت العلم والإبداع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF245344))),
              SizedBox(height: 8),
              Text('مرحباً بكم في مدرسة كوثر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('بيئة تعليمية آمنة ومحفزة، نؤمن أن لكل طالب موهبة تستحق الرعاية.'),
            ]),
          ),
          const SizedBox(height: 14),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            const Icon(Icons.campaign, color: Color(0xFF579B83)),
            const SizedBox(width: 10),
            Expanded(child: SizedBox(height: 26, child: news.isEmpty
              ? const Align(alignment: Alignment.centerRight, child: Text('أخبار وإعلانات المدرسة'))
              : _NewsTicker(items: news, paused: paused))),
            IconButton(onPressed: () => setState(() => paused = !paused),
              icon: Icon(paused ? Icons.play_arrow : Icons.pause)),
          ]))),
          const SizedBox(height: 14),
          const Text('إحصائيات المدرسة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<int>>(future: Future.wait([
            safeCount('students'), safeCount('top_students'), safeCount('announcements'), Future.value(2026)
          ]), builder: (context, snap) {
            final v = snap.data ?? [0,0,0,2026];
            return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, childAspectRatio: 1.75, crossAxisSpacing: 10, mainAxisSpacing: 10,
              children: [
                _StatCard('الطلبة', '${v[0]}', Icons.people_alt_outlined),
                _StatCard('المتفوقون', '${v[1]}', Icons.emoji_events_outlined),
                _StatCard('العام الدراسي', '2026–2027', Icons.calendar_month_outlined),
                _StatCard('الإعلانات', '${v[2]}', Icons.notifications_active_outlined),
              ]);
          }),
          const SizedBox(height: 18),
          const Text('أقسام المدرسة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 1.55, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: sections.length,
            itemBuilder: (context, i) => InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SectionScreen(title: sections[i].$1, table: sections[i].$3, canEdit: isAdmin || (role == 'teacher' && ['grades','attendance'].contains(sections[i].$3))))),
              child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(sections[i].$2, size: 30, color: const Color(0xFF579B83)),
                  const SizedBox(height: 8),
                  Text(sections[i].$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                ]))),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
              icon: const Icon(Icons.admin_panel_settings), label: const Text('لوحة الإدارة')),
          ],
        ],
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon;
  const _StatCard(this.title, this.value, this.icon);
  @override Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(backgroundColor: const Color(0xFFE6F4ED), child: Icon(icon, color: const Color(0xFF579B83))),
      const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ])),
    ])));
}

class _NewsTicker extends StatefulWidget {
  final List<Map<String,dynamic>> items; final bool paused;
  const _NewsTicker({required this.items, required this.paused});
  @override State<_NewsTicker> createState() => _NewsTickerState();
}
class _NewsTickerState extends State<_NewsTicker> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  @override void didUpdateWidget(covariant _NewsTicker oldWidget) { super.didUpdateWidget(oldWidget); widget.paused ? controller.stop() : controller.repeat(); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ClipRect(child: AnimatedBuilder(animation: controller, builder: (_, __) {
    final text = widget.items.map((e) => e['title']?.toString() ?? '').where((e) => e.isNotEmpty).join('     •     ');
    return Align(alignment: Alignment((controller.value * 2) - 1, 0), child: Text(text, maxLines: 1, softWrap: false));
  }));
}
