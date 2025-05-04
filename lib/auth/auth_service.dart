import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

      await _supabase.from('login_history').insert({
        'user_id': user.id,
        'login_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _supabase
          .from('profiles')
          .update({'last_sign_in_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', user.id);

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

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, phone_number, role, email');
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Debug: Error fetching users: $e');
      throw 'Lỗi khi lấy danh sách người dùng: $e';
    }
  }

  Future<String?> addUser({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          userMetadata: {'full_name': fullName},
        ),
      );
      if (response.user == null) {
        return 'Không thể tạo tài khoản, vui lòng kiểm tra lại email/mật khẩu';
      }

      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'user',
      });

      return null;
    } catch (e) {
      print('Debug: Error adding user: $e');
      return 'Lỗi khi thêm tài khoản: $e';
    }
  }

  Future<String?> updateUser({
    required String userId,
    required String fullName,
    String? phoneNumber,
    required String role,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone_number': phoneNumber,
            'role': role,
          })
          .eq('id', userId);
      return null;
    } catch (e) {
      print('Debug: Error updating user: $e');
      return 'Lỗi khi cập nhật tài khoản: $e';
    }
  }

  Future<String?> deleteUser(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
      await _supabase.auth.admin.deleteUser(userId);
      return null;
    } catch (e) {
      print('Debug: Error deleting user: $e');
      return 'Lỗi khi xóa tài khoản: $e';
    }
  }

  Future<bool> isAdmin() async {
    final user = getCurrentUser();
    if (user == null) {
      print('Debug: No current user found for admin check');
      return false;
    }
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
      if (response == null) {
        print('Debug: Profile not found for user: ${user.id}');
        return false;
      }
      return response['role'] == 'admin';
    } catch (e) {
      print('Debug: Error checking admin status: $e');
      return false;
    }
  }

  User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    print('Debug: Current user: ${user?.id}');
    return user;
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = getCurrentUser();
    if (user == null) {
      print('Debug: No current user found');
      return null;
    }
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('id, full_name, phone_number, role')
              .eq('id', user.id)
              .maybeSingle();
      if (response == null) {
        print('Debug: Profile not found for user: ${user.id}');
        return null;
      }
      final userEmail = user.email ?? 'No email';
      print('Debug: Profile found: $response');
      return {...response, 'email': userEmail};
    } catch (e) {
      print('Debug: Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    print('Debug: Signing out user...');
    await _supabase.auth.signOut();
    print('Debug: Sign out completed.');
  }

  Future<String?> recordTime({
    required bool isCheckIn,
    int lateMinutes = 0,
    int earlyMinutes = 0,
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      print('Debug: Error: No current user found.');
      return 'Không tìm thấy người dùng hiện tại';
    }

    try {
      print('Debug: Fetching last time record for user: ${user.id}');
      final lastRecord =
          await _supabase
              .from('time_records')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
      print('Debug: Last record: $lastRecord');

      if (isCheckIn) {
        if (lastRecord != null && lastRecord['check_out'] == null) {
          print('Debug: User already checked in, must check out first.');
          return 'Bạn đã check-in trước đó, vui lòng check-out trước';
        }
        print('Debug: Inserting new check-in record...');
        await _supabase.from('time_records').insert({
          'user_id': user.id,
          'check_in': DateTime.now().toUtc().toIso8601String(),
          'late_minutes': lateMinutes,
        });
        print('Debug: Check-in successful.');
        return null;
      } else {
        if (lastRecord == null || lastRecord['check_out'] != null) {
          print('Debug: User must check-in first.');
          return 'Bạn chưa check-in, vui lòng check-in trước';
        }
        print('Debug: Updating check-out record...');
        await _supabase
            .from('time_records')
            .update({
              'check_out': DateTime.now().toUtc().toIso8601String(),
              'early_minutes': earlyMinutes,
            })
            .eq('id', lastRecord['id']);
        print('Debug: Check-out successful.');
        return null;
      }
    } catch (e) {
      print('Debug: Error during time recording: $e');
      return 'Lỗi khi chấm công: $e';
    }
  }

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
      print('Debug: Error fetching time records: $e');
      throw 'Lỗi khi lấy lịch sử chấm công: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getRecentLogins() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, last_sign_in_at')
          .not('last_sign_in_at', 'is', null)
          .order('last_sign_in_at', ascending: false)
          .limit(10);
      final users = response as List<Map<String, dynamic>>;

      if (users.isEmpty) {
        return [];
      }

      final mappedUsers =
          users.map((user) {
            final loginTime = DateTime.parse(user['last_sign_in_at']);
            final timeDiff = DateTime.now().difference(loginTime);
            String timeAgo;
            if (timeDiff.inMinutes < 5) {
              timeAgo = 'Vừa đăng nhập';
            } else if (timeDiff.inMinutes < 60) {
              timeAgo = '${timeDiff.inMinutes} phút trước';
            } else if (timeDiff.inHours < 24) {
              timeAgo = '${timeDiff.inHours} giờ trước';
            } else {
              timeAgo = '${timeDiff.inDays} ngày trước';
            }

            return {
              'id': user['id'],
              'full_name': user['full_name'] ?? 'Chưa đặt tên',
              'last_sign_in_at': user['last_sign_in_at'],
              'time_ago': timeAgo,
            };
          }).toList();

      return mappedUsers;
    } catch (e) {
      print('Debug: Lỗi khi lấy danh sách đăng nhập gần đây: $e');
      throw 'Lỗi khi lấy danh sách đăng nhập gần đây: $e';
    }
  }

  Future<void> addNotification(String message) async {
    final user = getCurrentUser();
    if (user == null) {
      throw 'Không tìm thấy người dùng hiện tại';
    }
    try {
      await _supabase.from('notifications').insert({
        'user_id': user.id,
        'message': message,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('Debug: Error adding notification: $e');
      throw 'Lỗi khi lưu thông báo: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = getCurrentUser();
    if (user == null) {
      throw 'Không tìm thấy người dùng hiện tại';
    }
    try {
      final response = await _supabase
          .from('notifications')
          .select('id, message, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Debug: Error fetching notifications: $e');
      throw 'Lỗi khi lấy danh sách thông báo: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getUsersWithSalary() async {
    try {
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, role, email');
      final users = response as List<Map<String, dynamic>>;

      for (var user in users) {
        String department = user['role'] ?? 'Unknown';
        double baseSalary = _getBaseSalary(department);
        int workDays = await _countWorkDays(
          user['id'],
          currentMonth,
          currentYear,
        );
        int totalLateMinutes = await _calculateLatePenalty(
          user['id'],
          currentMonth,
          currentYear,
        );
        double latePenalty = totalLateMinutes > 30 ? 200000 : 0;
        double totalSalary =
            baseSalary + (workDays * (baseSalary / 26)) - latePenalty;

        user['base_salary'] = baseSalary;
        user['work_days'] = workDays;
        user['late_penalty'] = latePenalty;
        user['total_salary'] = totalSalary;
      }
      return users;
    } catch (e) {
      print('Debug: Error fetching users with salary: $e');
      throw 'Lỗi khi lấy danh sách người dùng với lương: $e';
    }
  }

  Future<Map<String, dynamic>> getUserSalary(String userId) async {
    try {
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      final response =
          await _supabase
              .from('profiles')
              .select('id, full_name, role, email')
              .eq('id', userId)
              .single();
      String department = response['role'] ?? 'Unknown';
      double baseSalary = _getBaseSalary(department);
      int workDays = await _countWorkDays(userId, currentMonth, currentYear);
      int totalLateMinutes = await _calculateLatePenalty(
        userId,
        currentMonth,
        currentYear,
      );
      double latePenalty = totalLateMinutes > 30 ? 200000 : 0;
      double totalSalary =
          baseSalary + (workDays * (baseSalary / 26)) - latePenalty;

      return {
        ...response,
        'base_salary': baseSalary,
        'work_days': workDays,
        'late_penalty': latePenalty,
        'total_salary': totalSalary,
      };
    } catch (e) {
      print('Debug: Error fetching user salary: $e');
      throw 'Lỗi khi lấy thông tin lương: $e';
    }
  }

  double _getBaseSalary(String department) {
    switch (department.toLowerCase()) {
      case 'it':
        return 6000000;
      case 'sale':
        return 5000000;
      case 'marketing':
        return 4500000;
      default:
        return 0;
    }
  }

  Future<int> _countWorkDays(String userId, int month, int year) async {
    try {
      final response = await _supabase
          .from('time_records')
          .select('check_out')
          .eq('user_id', userId)
          .gte('check_out', DateTime(year, month).toIso8601String())
          .lte('check_out', DateTime(year, month + 1, 0).toIso8601String())
          .not('check_out', 'is', null);
      return response.length;
    } catch (e) {
      print('Debug: Error counting work days: $e');
      return 0;
    }
  }

  Future<int> _calculateLatePenalty(String userId, int month, int year) async {
    try {
      final response = await _supabase
          .from('time_records')
          .select('late_minutes')
          .eq('user_id', userId)
          .gte('check_in', DateTime(year, month).toIso8601String())
          .lte('check_in', DateTime(year, month + 1, 0).toIso8601String());
      int totalLateMinutes = 0;
      for (var record in response) {
        totalLateMinutes += (record['late_minutes'] as int?) ?? 0;
      }
      return totalLateMinutes;
    } catch (e) {
      print('Debug: Error calculating late penalty: $e');
      return 0;
    }
  }
}
