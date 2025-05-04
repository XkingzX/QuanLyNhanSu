import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // Xử lý đăng nhập
  Future<String?> _login(LoginData data) async {
    final authService = AuthService();

    try {
      print('Debug: Đang đăng nhập với email: ${data.name}');
      final error = await authService.signIn(data.name, data.password);

      if (error != null) {
        print('Debug: Lỗi đăng nhập: $error');
        if (error == 'Tài khoản này không tồn tại') {
          return 'Tài khoản không tồn tại';
        } else if (error ==
            'Đăng nhập thất bại: Thiếu tài khoản hoặc mật khẩu') {
          return 'Sai email hoặc mật khẩu';
        }
        return error;
      }

      print('Debug: Đăng nhập thành công');
      return null; // null nghĩa là thành công
    } catch (e) {
      print('Debug: Lỗi ngoại lệ trong _login: $e');
      return 'Lỗi hệ thống: ${e.toString()}';
    }
  }

  // Khôi phục mật khẩu
  Future<String?> _recoverPassword(String email) async {
    final authService = AuthService();
    return await authService.recoverPassword(email);
  }

  // Khi hoàn tất animation login
  Future<void> _onSubmitAnimationCompleted(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy người dùng sau khi đăng nhập');
      }

      print('Debug: Người dùng hiện tại ID: ${user.id}');

      // Điều hướng vào HomePage, tại đó sẽ xử lý phân quyền
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      print('Debug: Lỗi sau animation login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        title: 'Quản lý nhân sự',
        logo: const AssetImage('assets/logo_app.png'),
        onLogin: _login,
        onRecoverPassword: _recoverPassword,
        onSubmitAnimationCompleted: () => _onSubmitAnimationCompleted(context),
        messages: LoginMessages(
          userHint: 'Email',
          passwordHint: 'Mật khẩu',
          loginButton: 'Đăng nhập',
          forgotPasswordButton: 'Quên mật khẩu?',
          recoverPasswordButton: 'Khôi phục',
          goBackButton: 'Quay lại',
          recoverPasswordDescription:
              'Nhập email của bạn để nhận liên kết khôi phục mật khẩu.',
          recoverPasswordSuccess: 'Đã gửi liên kết khôi phục thành công!',
          flushbarTitleError: 'Lỗi',
          flushbarTitleSuccess: 'Thành công',
        ),
        theme: LoginTheme(
          primaryColor: Colors.green,
          accentColor: Colors.greenAccent,
          errorColor: Colors.red,
          cardTheme: const CardTheme(
            color: Colors.white,
            elevation: 8,
            margin: EdgeInsets.symmetric(horizontal: 24),
          ),
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
          bodyStyle: const TextStyle(color: Colors.black87, fontSize: 16.0),
          buttonStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
          inputTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.green.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
            ),
          ),
          buttonTheme: const LoginButtonTheme(
            backgroundColor: Colors.green,
            highlightColor: Colors.greenAccent,
            splashColor: Colors.greenAccent,
            elevation: 4.0,
            highlightElevation: 6.0,
          ),
        ),
      ),
    );
  }
}
