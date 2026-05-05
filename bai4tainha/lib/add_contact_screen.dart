import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'db_helper.dart';

class AddContactScreen extends StatefulWidget {
  final Map<String, dynamic>? contact;

  const AddContactScreen({super.key, this.contact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _avatar;
  Uint8List? _existingAvatar;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!['name'] ?? '';
      _phoneController.text = widget.contact!['phone'] ?? '';
      _emailController.text = widget.contact!['email'] ?? '';
      _existingAvatar = widget.contact!['avatar'];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _avatar = File(pickedFile.path);
          _existingAvatar = null;
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên và số điện thoại không được để trống!'),
        ),
      );
      return;
    }

    Uint8List? finalAvatar;
    if (_avatar != null) {
      finalAvatar = await _avatar!.readAsBytes();
    } else if (_existingAvatar != null) {
      finalAvatar = _existingAvatar;
    }

    final contactData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'avatar': finalAvatar,
    };

    if (widget.contact != null) {
      contactData['id'] = widget.contact!['id'];
      await DBHelper().updateContact(contactData);
    } else {
      await DBHelper().insertContact(contactData);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact != null ? 'Sửa danh bạ' : 'Thêm danh bạ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatar != null
                      ? FileImage(_avatar!)
                      : (_existingAvatar != null
                                ? MemoryImage(_existingAvatar!)
                                : null)
                            as ImageProvider?,
                  child: _avatar == null && _existingAvatar == null
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveContact, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }
}
