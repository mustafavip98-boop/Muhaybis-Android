import 'package:flutter/material.dart';

void main() => runApp(const MuhaybisApp());

class MuhaybisApp extends StatelessWidget {
  const MuhaybisApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'المحيبس',
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B111B),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD6A85F), brightness: Brightness.dark),
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int hands = 8;
  String roomType = 'عام';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المحيبس', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.sports_esports, size: 72, color: Color(0xFFD6A85F)),
        const SizedBox(height: 14),
        const Center(child: Text('لعبة المحيبس العراقية', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        const Center(child: Text('مجالس • تحدّي • تراث', style: TextStyle(color: Colors.white60))),
        const SizedBox(height: 36),
        const Text('عدد العضمات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 4, label: Text('4 عضمات')),
            ButtonSegment(value: 8, label: Text('8 عضمات')),
          ],
          selected: {hands},
          onSelectionChanged: (v) => setState(() => hands = v.first),
        ),
        const SizedBox(height: 24),
        const Text('نوع المجلس', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'عام', label: Text('مجلس عام')),
            ButtonSegment(value: 'خاص', label: Text('مجلس خاص')),
          ],
          selected: {roomType},
          onSelectionChanged: (v) => setState(() => roomType = v.first),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('قريباً'),
              content: Text('تم اختيار $hands عضمات — مجلس $roomType. ربط اللعب الجماعي والخادم قيد التجهيز.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
            ),
          ),
          icon: const Icon(Icons.add_circle_outline),
          label: const Padding(padding: EdgeInsets.all(8), child: Text('إنشاء مجلس', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) {
              final code = TextEditingController();
              return AlertDialog(
                title: const Text('الانضمام لمجلس'),
                content: TextField(controller: code, decoration: const InputDecoration(labelText: 'رمز الدعوة')),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))],
              );
            },
          ),
          icon: const Icon(Icons.login),
          label: const Padding(padding: EdgeInsets.all(8), child: Text('الانضمام برمز')),
        ),
        const SizedBox(height: 30),
        const Center(child: Text('نسخة أولية — الاتصال بالأونلاين والصوت المباشر يحتاج إعداد الخادم', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
      ],
    )),
  );
}
