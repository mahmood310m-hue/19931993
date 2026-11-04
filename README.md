# تطبيق مدرسة كوثر الأهلية المختلطة

مشروع Flutter عربي RTL متصل بـ Supabase (PostgreSQL + Auth + Storage)، ومهيأ للبناء عبر GitHub Actions.

## المتطلبات
- Flutter stable (Dart 3.4 أو أحدث)
- مشروع Supabase مجاني
- Android SDK حديث

## الإعداد
1. أنشئ مشروعاً في https://supabase.com.
2. افتح SQL Editor ونفّذ `supabase/migrations/0001_initial_schema.sql`.
3. من Project Settings > API انسخ Project URL و anon/public key.
4. شغّل التطبيق هكذا:
   ```bash
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```
5. فعّل Phone Auth في Supabase. تسجيل الدخول في التطبيق يستخدم رقم الهاتف وكلمة المرور. إعداد مزود SMS مطلوب فقط إذا أردت تدفق OTP/تأكيد الهاتف.
6. أنشئ المستخدمين من Supabase Auth، ثم أضف صفوفهم في `profiles` مع `role` المناسب. لا تمنح دور `super_admin` إلا لحساب موثوق.
7. أنشئ bucket باسم `school-media` واجعله private، ثم اضبط سياسات التخزين حسب الحاجة.

## الأمان
- التطبيق يستخدم anon key فقط، وهو مفتاح عميل قابل للاستخراج وليس سراً.
- لا تضع `service_role` أو كلمات المرور أو مفاتيح الإدارة في التطبيق أو GitHub.
- الصلاحيات الحقيقية مفروضة في PostgreSQL عبر RLS. إخفاء عناصر الواجهة ليس بديلاً عن RLS.
- سياسات الدرجات والحضور تقيد المعلم بالصفوف/المواد المسندة إليه، والطالب/ولي الأمر ببياناته المرتبطة.
- راجع السياسات قبل إدخال بيانات طلاب حقيقية، واستعن بمسؤول قاعدة بيانات لمراجعة متطلبات الخصوصية المحلية.

## بناء APK محلياً
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
الناتج: `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions
أضف Secrets باسم:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

ثم ادفع إلى `main` أو شغّل workflow يدوياً. سيُرفق APK كـ Artifact باسم `kauthar-school-apk`.

## ملاحظات مهمة
- هذا مستودع مصدر قابل للتطوير وليس APK مبنياً مسبقاً. يلزم تشغيل البناء في بيئة Flutter/Android للتحقق النهائي من APK.
- دعم العمل دون إنترنت غير مفعّل في هذا الإصدار؛ يلزم إضافة تخزين محلي ومزامنة موثوقة قبل اعتماد هذه الميزة.
- إعدادات Firebase غير مطلوبة.
