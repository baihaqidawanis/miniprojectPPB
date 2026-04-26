import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/news_model.dart';
import 'storage_service.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Stream<List<NewsModel>> getNewsStream() {
    return _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList());
  }

  Future<void> createNews(NewsModel news, {File? photo}) async {
    try {
      final docRef = _firestore.collection('news').doc();
      final newsId = docRef.id;

      String? photoUrl;
      if (photo != null) {
        photoUrl = await _storageService.uploadNewsPhoto(photo, newsId);
      }

      final finalNews = NewsModel(
        id: newsId,
        title: news.title,
        content: news.content,
        photoUrl: photoUrl,
        createdAt: news.createdAt,
        authorId: news.authorId,
        authorName: news.authorName,
      );

      await docRef.set(finalNews.toMap());
    } catch (e) {
      print('Error creating news: $e');
      rethrow;
    }
  }

  Future<void> deleteNews(NewsModel news) async {
    try {
      if (news.photoUrl != null) {
        await _storageService.deleteByUrl(news.photoUrl!);
      }
      await _firestore.collection('news').doc(news.id).delete();
    } catch (e) {
      print('Error deleting news: $e');
    }
  }
}
