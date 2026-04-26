import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? photoUrl;
  final DateTime createdAt;
  final String authorId;
  final String authorName;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.photoUrl,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'authorName': authorName,
    };
  }
}
