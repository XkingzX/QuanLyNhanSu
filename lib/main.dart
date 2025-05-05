import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Kết nối API Supabase
  await Supabase.initialize(
    url: 'https://yzdhnmfaaekqmymjxtwx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6ZGhubWZhYWVrcW15bWp4dHd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyNzMxMjUsImV4cCI6MjA2MTg0OTEyNX0.TV8LVuhtjk4xVpKGcxKUyZ9asGzQH7r9FXvX2YCeUbg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý nhân sự',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home:
          Supabase.instance.client.auth.currentUser != null
              ? const HomePage()
              : const LoginPage(),
    );
  }
}
