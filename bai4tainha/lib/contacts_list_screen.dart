import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_contact_screen.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts([String keyword = '']) async {
    setState(() {
      _isLoading = true;
    });
    
    List<Map<String, dynamic>> contacts;
    if (keyword.isEmpty) {
      contacts = await DBHelper().getContacts();
    } else {
      contacts = await DBHelper().searchContacts(keyword);
    }
    
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _deleteContact(int id) async {
    await DBHelper().deleteContact(id);
    _loadContacts(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.purple),
        title: const Text(
          'My Contacts',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddContactScreen(),
                ),
              );
              if (result == true) {
                _loadContacts(_searchController.text);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _loadContacts(value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? const Center(child: Text('Không có danh bạ nào.'))
                    : ListView.separated(
                        itemCount: _contacts.length,
                        separatorBuilder: (context, index) => const Divider(
                          indent: 70,
                          endIndent: 16,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return ListTile(
                            leading: contact['avatar'] != null
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage: MemoryImage(contact['avatar']),
                                  )
                                : const CircleAvatar(
                                    radius: 24,
                                    child: Icon(Icons.person),
                                  ),
                            title: Text(
                              contact['name'] ?? 'Không có tên',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              contact['phone'] ?? 'Không có số',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddContactScreen(contact: contact),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadContacts(_searchController.text);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteContact(contact['id']),
                                ),
                              ],
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
