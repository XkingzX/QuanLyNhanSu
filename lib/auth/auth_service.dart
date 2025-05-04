import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Đăng nhập với email và mật khẩu
  Future<String?> signIn(String email, String password) async {
    try {
      print(
        'Debug: Attempting to sign in with email: $email, password: $password',
      );
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Debug: SignIn response: $response');
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Debug: No user logged in after sign in');
        return 'Đăng nhập không thành công, không tìm thấy người dùng';
      }

      // Ghi nhận thời gian đăng nhập
      await _supabase.from('login_history').insert({'user_id': user.id});
      print('Debug: Sign in successful for $email, User ID: ${user.id}');
      return null;
    } on AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        print('Debug: Đăng nhập thất bại: Thiếu tài khoản hoặc mật khẩu');
        return 'Đăng nhập thất bại: Thiếu tài khoản hoặc mật khẩu';
      }
      print(
        'Debug: AuthException during sign in: ${e.message}, Code: ${e.code}',
      );
      return e.message;
    } catch (e) {
      print('Debug: Unexpected error during sign in: $e');
      return 'Đã xảy ra lỗi khi đăng nhập: $e';
    }
  }

  // Gửi email khôi phục mật khẩu
  Future<String?> recoverPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Đã xảy ra lỗi khi gửi email khôi phục: $e';
    }
  }

  // Lấy danh sách người dùng (cho admin)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase.from('profiles').select('''
            id,
            full_name,
            phone_number,
            role,
            auth.users!inner(email)
          ''');
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      if (e is PostgrestException) {
        throw 'Lỗi khi lấy danh sách người dùng: $e';
      }
      throw 'Lỗi không xác định khi lấy danh sách người dùng: $e';
    }
  }

  // Thêm tài khoản mới (cho admin)
  Future<String?> addUser({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'phone_number': phoneNumber ?? '',
          'role': 'user', // Mặc định là user, có thể thay đổi sau
        });
      }
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Đã xảy ra lỗi khi thêm tài khoản: $e';
    }
  }

  // Cập nhật thông tin người dùng (cho admin)
  Future<String?> updateUser({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? role,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            if (fullName != null) 'full_name': fullName,
            if (phoneNumber != null) 'phone_number': phoneNumber,
            if (role != null) 'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return null;
    } catch (e) {
      return 'Lỗi khi cập nhật người dùng: $e';
    }
  }

  // Xóa người dùng (cho admin)
  Future<String?> deleteUser(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
      // Xóa người dùng khỏi auth (nếu cần)
      await _supabase.auth.admin.deleteUser(userId);
      return null;
    } catch (e) {
      return 'Lỗi khi xóa người dùng: $e';
    }
  }

  // Kiểm tra vai trò admin
  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('Debug: No user logged in');
      return false;
    }

    try {
      final response =
          await _supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();
      print('Debug: User ID: ${user.id}, Role: ${response['role']}');

      if (response == null ||
          !response.containsKey('role') ||
          response['role'] == null) {
        print('Debug: No role found for user ID: ${user.id}');
        return false;
      }

      final role = response['role'] as String;
      print('Debug: Role checked: $role');
      return role == 'admin';
    } catch (e) {
      print('Debug: Error in isAdmin: $e');
      return false;
    }
  }

  // Lấy thông tin người dùng hiện tại
  User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    print('Current user: ${user?.id}'); // Debug log
    return user;
  }

  // Đăng xuất
  Future<void> signOut() async {
    print('Signing out user...');
    await _supabase.auth.signOut();
    print('Sign out completed.');
  }

  // Chấm công (check-in/check-out)
  Future<String?> recordTime({
    required bool isCheckIn,
    int lateMinutes = 0,
    int earlyMinutes = 0,
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      print('Error: No current user found.');
      return 'Không tìm thấy người dùng hiện tại';
    }

    try {
      print('Fetching last time record for user: ${user.id}');
      final lastRecord =
          await _supabase
              .from('time_records')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
      print('Last record: $lastRecord');

      if (isCheckIn) {
        if (lastRecord != null && lastRecord['check_out'] == null) {
          print('User already checked in, must check out first.');
          return 'Bạn đã check-in trước đó, vui lòng check-out trước';
        }
        print('Inserting new check-in record...');
        await _supabase.from('time_records').insert({
          'user_id': user.id,
          'check_in': DateTime.now().toUtc().toIso8601String(),
          'late_minutes': lateMinutes,
        });
        print('Check-in successful.');
        return null;
      } else {
        if (lastRecord == null || lastRecord['check_out'] != null) {
          print('User must check-in first.');
          return 'Bạn chưa check-in, vui lòng check-in trước';
        }
        print('Updating check-out record...');
        await _supabase
            .from('time_records')
            .update({
              'check_out': DateTime.now().toUtc().toIso8601String(),
              'early_minutes': earlyMinutes,
            })
            .eq('id', lastRecord['id']);
        print('Check-out successful.');
        return null;
      }
    } catch (e) {
      print('Error during time recording: $e');
      return 'Lỗi khi chấm công: $e';
    }
  }

  // Lấy lịch sử chấm công
  Future<List<Map<String, dynamic>>> getTimeRecords() async {
    final user = getCurrentUser();
    if (user == null) {
      throw 'Không tìm thấy người dùng hiện tại';
    }

    try {
      final response = await _supabase
          .from('time_records')
          .select(
            'id, user_id, check_in, check_out, late_minutes, early_minutes',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw 'Lỗi khi lấy lịch sử chấm công: $e';
    }
  }

  // Lấy danh sách người dùng vừa đăng nhập
  Future<List<Map<String, dynamic>>> getRecentLogins() async {
    try {
      final response = await _supabase
          .from('login_history')
          .select('user_id, login_time')
          .order('login_time', ascending: false)
          .limit(5);
      final logins = response as List<dynamic>;

      final userIds = logins.map((login) => login['user_id']).toList();
      final users = await _supabase
          .from('profiles')
          .select('id, full_name')
          .contains('id', userIds);
      final userMap = {for (var u in users) u['id']: u['full_name']};

      return logins.map((login) {
        return {
          'user_id': login['user_id'],
          'login_time': login['login_time'],
          'full_name': userMap[login['user_id']] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      throw 'Lỗi khi lấy danh sách đăng nhập: $e';
    }
  }

  // Lưu thông báo
  Future<String?> saveNotification(String message) async {
    try {
      await _supabase.from('notifications').insert({
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (e) {
      return 'Lỗi khi lưu thông báo: $e';
    }
  }

  // Lấy thông báo mới nhất
  Future<String?> getLatestNotification() async {
    try {
      final response =
          await _supabase
              .from('notifications')
              .select('message')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
      return response != null ? response['message'] as String : null;
    } catch (e) {
      throw 'Lỗi khi tải thông báo: $e';
    }
  }
}
