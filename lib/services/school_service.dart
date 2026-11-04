import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolService {
  final SupabaseClient db;
  SchoolService(this.db);

  Future<Map<String, dynamic>?> profile() async {
    final user = db.auth.currentUser;
    if (user == null) return null;
    return await db.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<List<Map<String, dynamic>>> rows(String table,
      {String orderBy = 'created_at'}) async {
    final data = await db.from(table).select().order(orderBy, ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> count(String table) async {
    final result = await db.from(table).select('id').count(CountOption.exact);
    return result.count;
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    await db.from(table).insert(values);
  }

  Future<void> update(String table, String id, Map<String, dynamic> values) async {
    await db.from(table).update(values).eq('id', id);
  }

  Future<void> delete(String table, String id) async {
    await db.from(table).delete().eq('id', id);
  }
}
