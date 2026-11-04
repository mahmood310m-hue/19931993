import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool obscure = true, busy = false;
  String? error;

  Future<void> login() async {
    if (phone.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        phone: phone.text.trim(),
        password: password.text,
      );
    } on AuthException catch (e) {
      setState(() => error = e.message == 'Invalid login credentials'
          ? 'رقم الهاتف أو كلمة المرور غير صحيح' : e.message);
    } catch (_) {
      setState(() => error = 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { phone.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: const Color(0xFFE5F4EE),
                borderRadius: BorderRadius.circular(26)),
              child: const Icon(Icons.school_rounded, size: 48, color: Color(0xFF4F9C83)),
            ),
            const SizedBox(height: 16),
            const Text('مدرسة كوثر الأهلية المختلطة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF24483D))),
            const Text('Kauthar Private Mixed School'),
            const SizedBox(height: 28),
            TextField(controller: phone, keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 14),
            TextField(controller: password, obscureText: obscure,
              decoration: InputDecoration(labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off))),
              onSubmitted: (_) => login()),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, height: 50,
              child: FilledButton(onPressed: busy ? null : login,
                child: busy ? const CircularProgressIndicator() : const Text('تسجيل الدخول'))),
            const SizedBox(height: 12),
            const Text('للحصول على حساب، يرجى مراجعة إدارة المدرسة.',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        )),
      ),
    ))),
  );
}
