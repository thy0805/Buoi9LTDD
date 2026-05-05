import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'add_contact_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (await Permission.contacts.request().isGranted) {
        // Lấy danh bạ kèm theo số điện thoại, email và ảnh
        List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có quyền truy cập danh bạ!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddContactScreen(),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 500));
              _loadContacts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Không có danh bạ nào.'))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    Contact contact = _contacts[index];
                    return ListTile(
                      leading: (contact.photo != null && contact.photo!.isNotEmpty)
                          ? CircleAvatar(
                              backgroundImage: MemoryImage(contact.photo!),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(contact.displayName),
                      subtitle: Text(
                        '${(contact.phones.isNotEmpty) ? contact.phones.first.number : 'Không có số'}\n${(contact.emails.isNotEmpty) ? contact.emails.first.address : 'Không có email'}',
                      ),
                    );
                  },
                ),
    );
  }
}
