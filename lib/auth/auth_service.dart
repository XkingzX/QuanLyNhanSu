import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Đăng nhập với email và mật khẩu
  Future<String?> signIn(String email, String password) async {
    try {
      final result = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (result.user == null) return 'Đăng nhập không thành công.';
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Lỗi không xác định: $e';
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
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, phone_number, role, auth.users(email)')
          .eq('id', 'auth.users.id');
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw 'Lỗi khi lấy danh sách người dùng: $e';
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
      await _supabase.rpc(
        'create_new_user',
        params: {
          'p_email': email,
          'p_password': password,
          'p_full_name': fullName,
          'p_phone_number': phoneNumber ?? '',
        },
      );
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
      return null;
    } catch (e) {
      return 'Lỗi khi xóa người dùng: $e';
    }
  }

  // Kiểm tra vai trò admin
  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle()
        .limit(1);
    return profile?['role'] == 'admin';
  }

  // Lấy thông tin người dùng hiện tại
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Chấm công (check-in/check-out)
  Future<String?> recordTime({required bool isCheckIn}) async {
    final user = getCurrentUser();
    if (user == null) {
      return 'Không tìm thấy người dùng hiện tại';
    }

    try {
      // Kiểm tra bản ghi chấm công gần nhất
      final lastRecord =
          await _supabase
              .from('time_records')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (isCheckIn) {
        // Nếu là check-in
        if (lastRecord != null && lastRecord['check_out'] == null) {
          return 'Bạn đã check-in trước đó, vui lòng check-out trước';
        }
        await _supabase.from('time_records').insert({
          'user_id': user.id,
          'check_in': DateTime.now().toIso8601String(),
        });
        return null; // Thành công
      } else {
        // Nếu là check-out
        if (lastRecord == null || lastRecord['check_out'] != null) {
          return 'Bạn chưa check-in, vui lòng check-in trước';
        }
        await _supabase
            .from('time_records')
            .update({'check_out': DateTime.now().toIso8601String()})
            .eq('id', lastRecord['id']);
        return null; // Thành công
      }
    } catch (e) {
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
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw 'Lỗi khi lấy lịch sử chấm công: $e';
    }
  }
}
