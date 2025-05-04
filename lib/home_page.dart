import 'package:flutter/material.dart';
import 'auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  List<Map<String, dynamic>> _timeRecords = [];
  bool _isCheckedIn = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTimeRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeRecords() async {
    try {
      final records = await _authService.getTimeRecords();
      setState(() {
        _timeRecords = records;
        if (records.isNotEmpty && records.first['check_out'] == null) {
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

  Future<void> _addUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final fullName = _fullNameController.text;
    final phoneNumber =
        _phoneNumberController.text.isEmpty
            ? null
            : _phoneNumberController.text;

    final error = await _authService.addUser(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm tài khoản thành công!')),
      );
      _emailController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _phoneNumberController.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
    }
  }

  Future<void> _recordTime() async {
    final error = await _authService.recordTime(isCheckIn: !_isCheckedIn);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCheckedIn ? 'Check-out thành công!' : 'Check-in thành công!',
          ),
        ),
      );
      await _loadTimeRecords(); // Cập nhật lại danh sách
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang Nhân Viên'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Chấm Công'), Tab(text: 'Thêm Tài Khoản')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab Chấm Công
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chấm Công',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child:
                        _timeRecords.isEmpty
                            ? const Center(
                              child: Text('Chưa có dữ liệu chấm công'),
                            )
                            : ListView.builder(
                              itemCount: _timeRecords.length,
                              itemBuilder: (context, index) {
                                final record = _timeRecords[index];
                                return ListTile(
                                  title: Text(
                                    'Check-in: ${record['check_in'] != null ? DateTime.parse(record['check_in']).toLocal().toString() : 'N/A'}',
                                  ),
                                  subtitle: Text(
                                    'Check-out: ${record['check_out'] != null ? DateTime.parse(record['check_out']).toLocal().toString() : 'Chưa check-out'}',
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
            // Tab Thêm Tài Khoản
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thêm Tài Khoản (Admin)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addUser,
                    child: const Text('Thêm Tài Khoản'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
