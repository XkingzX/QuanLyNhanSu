import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'auth/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  String _selectedMenu = 'Trang chủ';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await _authService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      if (!_isAdmin) {
        _selectedMenu = 'Trang chủ';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Quản lý nhân sự'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.lightBlueAccent),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedMenu = 'Trang chủ');
                  Navigator.pop(context);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/logo_app.png', width: 60, height: 60),
                    const SizedBox(height: 8),
                    const Text(
                      'Quản lý nhân sự',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _authService.getCurrentUserProfile(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Đang tải...',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                            'Không tìm thấy thông tin',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }
                        final user = snapshot.data!;
                        return Text(
                          'Tên người dùng: ${user['full_name'] ?? 'Chưa đặt tên'} - ${_isAdmin ? "Admin" : "User"}',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.indigoAccent),
              title: const Text('Trang chủ'),
              selected: _selectedMenu == 'Trang chủ',
              onTap: () {
                setState(() => _selectedMenu = 'Trang chủ');
                Navigator.pop(context);
              },
            ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigoAccent),
                title: const Text('Nhân viên'),
                selected: _selectedMenu == 'Nhân viên',
                onTap: () {
                  setState(() => _selectedMenu = 'Nhân viên');
                  Navigator.pop(context);
                },
              ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.indigoAccent,
                ),
                title: const Text('Báo cáo/Thông báo'),
                selected: _selectedMenu == 'Báo cáo/Thông báo',
                onTap: () {
                  setState(() => _selectedMenu = 'Báo cáo/Thông báo');
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.person_pin_outlined,
                color: Colors.indigoAccent,
              ),
              title: const Text('Thông tin cá nhân'),
              selected: _selectedMenu == 'Thông tin cá nhân',
              onTap: () {
                setState(() => _selectedMenu = 'Thông tin cá nhân');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.access_time,
                color: Colors.indigoAccent,
              ),
              title: const Text('Chấm công'),
              selected: _selectedMenu == 'Chấm công',
              onTap: () {
                setState(() => _selectedMenu = 'Chấm công');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.attach_money,
                color: Colors.indigoAccent,
              ),
              title: const Text('Lương'),
              selected: _selectedMenu == 'Lương',
              onTap: () {
                setState(() => _selectedMenu = 'Lương');
                Navigator.pop(context);
              },
            ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.indigoAccent),
                title: const Text('Danh sách lương'),
                selected: _selectedMenu == 'Danh sách lương',
                onTap: () {
                  setState(() => _selectedMenu = 'Danh sách lương');
                  Navigator.pop(context);
                },
              ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.local_fire_department_outlined,
                  color: Colors.indigoAccent,
                ),
                title: const Text('Phòng ban'),
                selected: _selectedMenu == 'Phòng ban',
                onTap: () {
                  setState(() => _selectedMenu = 'Phòng ban');
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body:
          _selectedMenu == 'Nhân viên'
              ? (_isAdmin
                  ? const pageNhanVien()
                  : const Center(
                    child: Text('Bạn không có quyền truy cập mục này!'),
                  ))
              : _selectedMenu == 'Thông tin cá nhân'
              ? const pageThongTinCaNhan()
              : _selectedMenu == 'Trang chủ'
              ? const pageTrangChu()
              : _selectedMenu == 'Báo cáo/Thông báo'
              ? const pageBaoCaoThongBao()
              : _selectedMenu == 'Chấm công'
              ? const pageChamCong()
              : _selectedMenu == 'Lương'
              ? const pageLuong()
              : _selectedMenu == 'Danh sách lương'
              ? const pageSalaryList()
              : _selectedMenu == 'Phòng ban'
              ? const pagePhongBan()
              : Center(
                child: Text('Màn hình $_selectedMenu (Chưa triển khai)'),
              ),
      floatingActionButton: Builder(
        builder:
            (context) => FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Chatbox'),
                        content: const Text('Chức năng đang được phát triển!'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                );
              },
              child: Lottie.asset('assets/chatbox.json'),
              backgroundColor: Colors.lightBlueAccent,
            ),
      ),
    );
  }
}

class pageTrangChu extends StatefulWidget {
  const pageTrangChu({super.key});

  @override
  State<pageTrangChu> createState() => _pageTrangChuState();
}

class _pageTrangChuState extends State<pageTrangChu> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _recentLogins = [];
  String _latestNotification =
      'Không có thông báo mới, chúc bạn một ngày làm việc tốt lành!';

  @override
  void initState() {
    super.initState();
    _loadRecentLogins();
    _loadLatestNotification();
  }

  Future<void> _loadRecentLogins() async {
    try {
      final logins = await _authService.getRecentLogins();
      print(
        'Danh sách người dùng vừa đăng nhập (trong _loadRecentLogins): $logins',
      );
      setState(() {
        _recentLogins = logins;
      });
    } catch (e) {
      print('Lỗi khi tải danh sách đăng nhập: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _loadLatestNotification() async {
    try {
      final notifications = await _authService.getNotifications();
      setState(() {
        _latestNotification =
            notifications.isNotEmpty
                ? notifications.first['message']
                : 'Không có thông báo mới, chúc bạn một ngày làm việc tốt lành!';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải thông báo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Báo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _latestNotification,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Người Dùng Vừa Đăng Nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _recentLogins.isEmpty
                ? const Center(
                  child: Text('Chưa có người dùng nào đăng nhập gần đây'),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentLogins.length,
                  itemBuilder: (context, index) {
                    final login = _recentLogins[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.lightBlue,
                        ),
                        title: Text(
                          login['time_ago'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          login['full_name'] ?? 'Chưa đặt tên',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color:
                                login['time_ago'] == 'Vừa đăng nhập'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class pageNhanVien extends StatefulWidget {
  const pageNhanVien({super.key});

  @override
  State<pageNhanVien> createState() => _pageNhanVienState();
}

class _pageNhanVienState extends State<pageNhanVien> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  bool _isVerified = false;
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getUsers();
      setState(() {
        _users = users ?? [];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addUser() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _isButtonEnabled = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ email, mật khẩu và họ tên'),
        ),
      );
      setState(() => _isButtonEnabled = true);
      return;
    }

    final result = await _authService.addUser(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm tài khoản thành công!')),
      );
      _emailController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _phoneNumberController.clear();
      setState(() => _isVerified = false); // Reset checkbox
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $result')));
    }

    // Delay 30 giây trước khi cho phép thêm lần tiếp theo
    await Future.delayed(const Duration(seconds: 30));
    setState(() => _isButtonEnabled = true);
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    _emailController.text = user['email'] ?? '';
    _fullNameController.text = user['full_name'] ?? '';
    _phoneNumberController.text = user['phone_number'] ?? '';
    bool isAdminRole = user['role'] == 'admin';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Chỉnh sửa nhân viên'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            filled: true,
                            fillColor: Colors.green.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            filled: true,
                            fillColor: Colors.green.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: isAdminRole,
                              onChanged: (value) {
                                setDialogState(() {
                                  isAdminRole = value ?? false;
                                });
                              },
                            ),
                            const Text('Vai trò: Admin'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                setState(() => _isLoading = true);
                                final result = await _authService.updateUser(
                                  userId: user['id'],
                                  fullName: _fullNameController.text.trim(),
                                  phoneNumber:
                                      _phoneNumberController.text.trim().isEmpty
                                          ? null
                                          : _phoneNumberController.text.trim(),
                                  role: isAdminRole ? 'admin' : 'user',
                                );
                                if (result == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cập nhật thành công!'),
                                    ),
                                  );
                                  await _loadUsers();
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $result')),
                                  );
                                }
                                setState(() => _isLoading = false);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    final result = await _authService.deleteUser(userId);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa tài khoản thành công!')),
      );
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $result')));
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm nhân viên mới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại (tùy chọn)',
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isVerified,
                    onChanged: (value) {
                      setState(() {
                        _isVerified = value ?? false;
                      });
                    },
                  ),
                  const Text('Xác Minh'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _addUser : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.indigoAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Thêm nhân viên',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Danh sách nhân viên',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigoAccent,
                ),
              ),
              const SizedBox(height: 16),
              _users.isEmpty
                  ? const Center(child: Text('Chưa có nhân viên nào'))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: SelectableText(
                            user['full_name'] ?? 'Không có tên',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                'Email: ${user['email'] ?? 'Chưa có'}',
                              ),
                              SelectableText(
                                'Số điện thoại: ${user['phone_number'] ?? 'Chưa có'}',
                              ),
                              SelectableText(
                                'Vai trò: ${user['role'] == 'admin' ? 'Admin' : 'User'}',
                              ),
                              if (user['is_verified'] != null)
                                SelectableText(
                                  'Trạng thái: ${user['is_verified'] ? 'Đã xác minh' : 'Chưa xác minh'}',
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.green,
                                ),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Xác nhận xóa'),
                                          content: Text(
                                            'Bạn có chắc muốn xóa nhân viên ${user['full_name'] ?? 'Chưa đặt tên'}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text(
                                                'Hủy',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  _isLoading
                                                      ? null
                                                      : () async {
                                                        await _deleteUser(
                                                          user['id'],
                                                        );
                                                        Navigator.pop(context);
                                                      },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              child: const Text(
                                                'Xóa',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        );
  }
}

class pageThongTinCaNhan extends StatelessWidget {
  const pageThongTinCaNhan({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Lỗi: Không tải được thông tin'));
        }
        final profile = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'Họ và tên: ${profile['full_name'] ?? 'Không có'}',
                      ),
                      const SizedBox(height: 8),
                      SelectableText('Email: ${profile['email'] ?? 'Chưa có'}'),
                      const SizedBox(height: 8),
                      SelectableText(
                        'Số điện thoại: ${profile['phone_number'] ?? 'Chưa có'}',
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        'Vai trò: ${profile['role'] == 'admin' ? 'Admin' : 'User'}',
                      ),
                      if (profile['is_verified'] != null)
                        SelectableText(
                          'Trạng thái: ${profile['is_verified'] ? 'Đã xác minh' : 'Chưa xác minh'}',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class pageBaoCaoThongBao extends StatefulWidget {
  const pageBaoCaoThongBao({super.key});

  @override
  State<pageBaoCaoThongBao> createState() => _pageBaoCaoThongBaoState();
}

class _pageBaoCaoThongBaoState extends State<pageBaoCaoThongBao> {
  final AuthService _authService = AuthService();
  final TextEditingController _notificationController = TextEditingController();
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _authService.getNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _saveNotification() async {
    final message = _notificationController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung thông báo')),
      );
      return;
    }

    try {
      await _authService.addNotification(message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm thông báo thành công!')),
      );
      _notificationController.clear();
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý Thông Báo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notificationController,
            decoration: InputDecoration(
              labelText: 'Nhập thông báo mới',
              filled: true,
              fillColor: Colors.green.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu thông báo'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Danh sách Thông Báo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                _notifications.isEmpty
                    ? const Center(child: Text('Chưa có thông báo nào'))
                    : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(notification['message']),
                            subtitle: Text(
                              'Ngày tạo: ${DateTime.parse(notification['created_at']).toLocal().toString()}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Danh sách Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _authService.getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('Lỗi: Không tải được danh sách admin'),
                );
              }
              final admins =
                  snapshot.data!
                      .where((user) => user['role'] == 'admin')
                      .toList();
              return admins.isEmpty
                  ? const Center(child: Text('Chưa có admin nào'))
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: SelectableText(
                            admin['full_name'] ?? 'Không có tên',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                'Email: ${admin['email'] ?? 'Chưa có'}',
                              ),
                              SelectableText(
                                'Số điện thoại: ${admin['phone_number'] ?? 'Chưa có'}',
                              ),
                              const SelectableText('Vai trò: Admin'),
                              if (admin['is_verified'] != null)
                                SelectableText(
                                  'Trạng thái: ${admin['is_verified'] ? 'Đã xác minh' : 'Chưa xác minh'}',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
            },
          ),
        ],
      ),
    );
  }
}

class pageChamCong extends StatefulWidget {
  const pageChamCong({super.key});

  @override
  State<pageChamCong> createState() => _pageChamCongState();
}

class _pageChamCongState extends State<pageChamCong> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _timeRecords = [];
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _loadTimeRecords();
  }

  Future<void> _loadTimeRecords() async {
    try {
      final records = await _authService.getTimeRecords();
      setState(() {
        _timeRecords = records ?? [];
        if (records != null &&
            records.isNotEmpty &&
            records.first['check_out'] == null) {
          _isCheckedIn = true;
        } else {
          _isCheckedIn = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _recordTime() async {
    final now = DateTime.now().toUtc();
    final checkInTime =
        DateTime(now.year, now.month, now.day, 8, 0, 0, 0, 0).toUtc();
    final checkOutTime =
        DateTime(now.year, now.month, now.day, 17, 30, 0, 0, 0).toUtc();
    int lateMinutes = 0;
    int earlyMinutes = 0;
    String message =
        _isCheckedIn ? 'Check-out thành công!' : 'Check-in thành công!';

    if (!_isCheckedIn) {
      if (now.isAfter(checkInTime)) {
        lateMinutes = now.difference(checkInTime).inMinutes;
        message = 'Check-in thành công! Bạn đã đi muộn $lateMinutes phút.';
      }
    } else {
      if (now.isBefore(checkOutTime)) {
        earlyMinutes = checkOutTime.difference(now).inMinutes;
        message =
            'Check-out thành công! Bạn đã checkout sớm $earlyMinutes phút.';
      }
    }

    final error = await _authService.recordTime(
      isCheckIn: !_isCheckedIn,
      lateMinutes: lateMinutes,
      earlyMinutes: earlyMinutes,
    );
    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadTimeRecords();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chấm Công',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _recordTime,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? Colors.red : Colors.green,
            ),
            child: Text(_isCheckedIn ? 'Check-out' : 'Check-in'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lịch Sử Chấm Công',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Expanded(
            child:
                _timeRecords.isEmpty
                    ? const Center(child: Text('Chưa có dữ liệu chấm công'))
                    : ListView.builder(
                      itemCount: _timeRecords.length,
                      itemBuilder: (context, index) {
                        final record = _timeRecords[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              'Check-in: ${record['check_in'] != null ? DateTime.parse(record['check_in']).toUtc().add(const Duration(hours: 7)).toString() : 'N/A'}'
                              '${record['late_minutes'] != null && record['late_minutes'] > 0 ? ' (Đi muộn ${record['late_minutes']} phút)' : ''}',
                            ),
                            subtitle: Text(
                              'Check-out: ${record['check_out'] != null ? DateTime.parse(record['check_out']).toUtc().add(const Duration(hours: 7)).toString() : 'Chưa check-out'}'
                              '${record['early_minutes'] != null && record['early_minutes'] > 0 ? ' (Checkout sớm ${record['early_minutes']} phút)' : ''}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class pageLuong extends StatefulWidget {
  const pageLuong({super.key});

  @override
  State<pageLuong> createState() => _pageLuongState();
}

class _pageLuongState extends State<pageLuong> {
  final AuthService _authService = AuthService();
  Map<String, dynamic> _userSalary = {};

  @override
  void initState() {
    super.initState();
    _loadUserSalary();
  }

  Future<void> _loadUserSalary() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _userSalary = {};
        });
        return;
      }
      final salary = await _authService.getUserSalary(user.id);
      setState(() {
        _userSalary = salary;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin lương'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin Lương',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            _userSalary.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu lương'))
                : Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Họ và tên: ${_userSalary['full_name'] ?? 'Chưa đặt tên'}',
                        ),
                        Text('Email: ${_userSalary['email'] ?? 'No email'}'),
                        Text('Phòng: ${_userSalary['role'] ?? 'Chưa đặt tên'}'),
                        Text(
                          'Lương cơ bản: ${_userSalary['base_salary']?.toStringAsFixed(0) ?? '0'} VND',
                        ),
                        Text('Số ngày công: ${_userSalary['work_days'] ?? 0}'),
                        Text(
                          'Phạt muộn: ${_userSalary['late_penalty'] > 0 ? '200,000 VND' : '0 VND'}',
                        ),
                        Text(
                          'Tổng lương: ${_userSalary['total_salary']?.toStringAsFixed(0) ?? '0'} VND',
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class pageSalaryList extends StatefulWidget {
  const pageSalaryList({super.key});

  @override
  State<pageSalaryList> createState() => _pageSalaryListState();
}

class _pageSalaryListState extends State<pageSalaryList> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _usersWithSalary = [];

  @override
  void initState() {
    super.initState();
    _loadUsersWithSalary();
  }

  Future<void> _loadUsersWithSalary() async {
    try {
      final users = await _authService.getUsersWithSalary();
      setState(() {
        _usersWithSalary = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Lương'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách Lương',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _usersWithSalary.isEmpty
                      ? const Center(child: Text('Chưa có dữ liệu lương'))
                      : ListView.builder(
                        itemCount: _usersWithSalary.length,
                        itemBuilder: (context, index) {
                          final user = _usersWithSalary[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                '${user['full_name'] ?? 'Chưa đặt tên'} - ${user['email'] ?? 'No email'}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phòng: ${user['role'] ?? 'Chưa đặt tên'}',
                                  ),
                                  Text(
                                    'Lương cơ bản: ${user['base_salary']?.toStringAsFixed(0) ?? '0'} VND',
                                  ),
                                  Text(
                                    'Số ngày công: ${user['work_days'] ?? 0}',
                                  ),
                                  Text(
                                    'Phạt muộn: ${user['late_penalty'] > 0 ? '200,000 VND' : '0 VND'}',
                                  ),
                                  Text(
                                    'Tổng lương: ${user['total_salary']?.toStringAsFixed(0) ?? '0'} VND',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class pagePhongBan extends StatelessWidget {
  const pagePhongBan({super.key});

  final List<Map<String, String>> _departments = const [
    {'id': '1', 'name': 'Phòng IT'},
    {'id': '2', 'name': 'Phòng Sale'},
    {'id': '3', 'name': 'Phòng Marketing'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phòng Ban'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách Phòng Ban',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final department = _departments[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(title: Text(department['name']!)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
