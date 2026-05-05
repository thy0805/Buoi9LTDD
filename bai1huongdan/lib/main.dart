import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainHomePage(),
    );
  }
}

class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main App')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Welcome to the Main App!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SmsReaderHome()),
              );
            },
            child: const Text(
              'Go to SMS Reader App',
              style: TextStyle(fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsReaderHome()),
              );
            },
            child: const Text(
              'Go to contacts Reader App',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class SmsReaderHome extends StatefulWidget {
  const SmsReaderHome({super.key});

  @override
  State<SmsReaderHome> createState() => _SmsReaderHomeState();
}

class _SmsReaderHomeState extends State<SmsReaderHome> {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [Permission.sms, Permission.phone].request();
    if (statuses[Permission.sms]!.isGranted) {
      _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cấp quyền để đọc tin nhắn SMS!')),
      );
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Reader')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text('Không có tin nhắn nào.'))
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    SmsMessage message = _messages[index];
                    return ListTile(
                      title: Text(message.body ?? 'Không có nội dung'),
                      subtitle: Text('Từ: ${message.address ?? 'Không rõ'}'),
                    );
                  },
                ),
    );
  }
}

class ContactsReaderHome extends StatefulWidget {
  const ContactsReaderHome({super.key});

  @override
  State<ContactsReaderHome> createState() => _ContactsReaderHomeState();
}

class _ContactsReaderHomeState extends State<ContactsReaderHome> {
  List<ContactInfo> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [Permission.contacts].request();
    if (statuses[Permission.contacts]!.isGranted) {
      _loadContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cấp quyền để đọc danh bạ!')),
      );
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    List<ContactInfo> contacts = await FlutterContactsService.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Reader')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Không có danh bạ nào.'))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    ContactInfo contact = _contacts[index];
                    return ListTile(
                      title: Text(contact.displayName ?? 'Không có tên'),
                      subtitle: Text(
                        contact.phones!.isNotEmpty
                            ? contact.phones?.first.value ?? 'Không có số'
                            : 'Không có số',
                      ),
                    );
                  },
                ),
    );
  }
}
