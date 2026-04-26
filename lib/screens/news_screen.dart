import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/news_model.dart';
import '../services/news_service.dart';
import '../providers/auth_provider.dart';
import 'admin_add_news_screen.dart';

class NewsScreen extends StatelessWidget {
  NewsScreen({super.key});
  final _newsService = NewsService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'BERITA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: user?.role == 'committee'
          ? FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAddNewsScreen()),
              ),
            )
          : null,
      body: StreamBuilder<List<NewsModel>>(
        stream: _newsService.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final newsList = snapshot.data;
          if (newsList == null || newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey.shade800),
                  const SizedBox(height: 16),
                  const Text('Belum ada berita.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) => _buildNewsCard(context, newsList[index], user),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news, dynamic user) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _NewsDetailScreen(news: news, user: user)),
      ),
      child: Card(
        color: Colors.grey.shade900,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.photoUrl != null)
              Image.network(
                news.photoUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.content,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(news.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      if (user?.role == 'committee')
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.grey.shade900,
                                title: const Text('Hapus Berita?', style: TextStyle(color: Colors.white)),
                                content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.grey)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) await _newsService.deleteNews(news);
                          },
                          child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        ),
                    ],
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

class _NewsDetailScreen extends StatelessWidget {
  final NewsModel news;
  final dynamic user;

  const _NewsDetailScreen({required this.news, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        actions: [
          if (user?.role == 'committee')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: const Text('Hapus Berita?', style: TextStyle(color: Colors.white)),
                    content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.grey)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await NewsService().deleteNews(news);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.photoUrl != null)
              Image.network(
                news.photoUrl!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy, HH:mm').format(news.createdAt)} · ${news.authorName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Text(news.content, style: TextStyle(color: Colors.grey.shade300, fontSize: 15, height: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
