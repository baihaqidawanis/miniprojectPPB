import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../providers/auth_provider.dart';

class AdminAddNewsScreen extends StatefulWidget {
  const AdminAddNewsScreen({super.key});

  @override
  State<AdminAddNewsScreen> createState() => _AdminAddNewsScreenState();
}

class _AdminAddNewsScreenState extends State<AdminAddNewsScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  File? _coverImage;
  final _picker = ImagePicker();
  final _newsService = NewsService();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
              title: const Text('Kamera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (picked != null) setState(() => _coverImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
              title: const Text('Galeri', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                if (picked != null) setState(() => _coverImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan konten wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel!;
      final news = NewsModel(
        id: '',
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: DateTime.now(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Admin',
      );
      await _newsService.createNews(news, photo: _coverImage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berita berhasil diterbitkan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Tulis Berita'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover photo picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                        image: _coverImage != null
                            ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _coverImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate, color: Colors.greenAccent, size: 40),
                                const SizedBox(height: 8),
                                Text('Tambah Foto Sampul (Opsional)', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Judul Berita',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  TextField(
                    controller: _contentCtrl,
                    style: const TextStyle(color: Colors.white, height: 1.6),
                    maxLines: null,
                    minLines: 10,
                    decoration: InputDecoration(
                      hintText: 'Tulis konten berita di sini...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text('TERBITKAN BERITA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
