import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  bool _isLoading = true;

  final TextEditingController _phoneFilterController = TextEditingController();
  final TextEditingController _sendPhoneController = TextEditingController();
  final TextEditingController _sendMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initSms();
  }

  Future<void> _initSms() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSms() async {
    final phone = _sendPhoneController.text.trim();
    final message = _sendMessageController.text.trim();
    if (phone.isEmpty || message.isEmpty) return;

    final Uri smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      _sendPhoneController.clear();
      _sendMessageController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showOTP(String text) {
    final match = RegExp(r'\d{4,6}').firstMatch(text);
    final otpCode = match != null ? match.group(0) : 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Mã xác thực OTP', textAlign: TextAlign.center),
        content: Text(
          otpCode!,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 5, color: Color(0xFF1A237E)),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analyzer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initSms,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Thống kê'),
            Tab(icon: Icon(Icons.sort_outlined), text: 'Phân loại'),
            Tab(icon: Icon(Icons.send_outlined), text: 'Gửi tin'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildStatsTab(), _buildFiltersTab(), _buildSendTab()],
            ),
    );
  }

  Widget _buildStatsTab() {
    String filter = _phoneFilterController.text.trim();
    List<SmsMessage> displayList = filter.isEmpty
        ? _messages
        : _messages.where((m) => m.address?.contains(filter) ?? false).toList();

    return RefreshIndicator(
      onRefresh: _initSms,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('TỔNG TIN NHẮN', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text('${_messages.length}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneFilterController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo số điện thoại...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 10),
          ...displayList.map((m) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.message_outlined, color: Color(0xFF1A237E)),
                  title: Text(m.address ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m.body ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(m.date != null ? DateFormat('HH:mm').format(m.date!) : '', style: const TextStyle(fontSize: 11)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    final qc = _messages.where((m) {
      final body = m.body?.toLowerCase() ?? '';
      return body.contains('[qc]') || body.contains('khuyen mai') || body.contains('uu dai') || body.contains('giam gia') || body.contains('uudai');
    }).toList();

    final otp = _messages.where((m) {
      final body = m.body?.toUpperCase() ?? '';
      final hasOtpKeyword = body.contains('OTP') || body.contains('XAC THUC') || body.contains('VERIFICATION') || body.contains('MA XAC NHAN');
      final hasNumberCode = RegExp(r'\d{4,6}').hasMatch(body);
      return hasOtpKeyword || (hasNumberCode && body.length < 100);
    }).toList();

    return RefreshIndicator(
      onRefresh: _initSms,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory('Tin nhắn Quảng cáo', qc, Icons.campaign_outlined, Colors.orange),
          const SizedBox(height: 15),
          _buildCategory('Mã xác thực OTP', otp, Icons.lock_outline, Colors.green),
          const SizedBox(height: 20),
          const Center(child: Text('Kéo xuống để cập nhật tin nhắn mới', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<SmsMessage> list, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text('$title (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: list.map((m) => ListTile(
          title: Text(m.address ?? ''),
          subtitle: Text(m.body ?? ''),
          onTap: title.contains('OTP') ? () => _showOTP(m.body ?? '') : null,
        )).toList(),
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.alternate_email, size: 60, color: Color(0xFF1A237E)),
          const SizedBox(height: 30),
          TextField(
            controller: _sendPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Người nhận', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _sendMessageController,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Nội dung tin nhắn', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _sendSms,
              child: const Text('GỬI TIN NHẮN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
