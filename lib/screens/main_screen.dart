import 'dart:async';
import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../models/news_model.dart';
import '../services/match_service.dart';
import '../services/news_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'news_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [HomeScreen(), NewsScreen()];

  // --- Notification Listeners ---
  late final StreamSubscription<List<MatchModel>> _matchSub;
  late final StreamSubscription<List<NewsModel>> _newsSub;

  // Simpan state sebelumnya untuk deteksi perubahan
  final Map<String, String> _prevStatus = {};  // matchId → status
  final Map<String, int> _prevHome = {};        // matchId → homeScore
  final Map<String, int> _prevAway = {};        // matchId → awayScore
  bool _matchFirstLoad = true;

  String? _newestNewsId;
  bool _newsFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startMatchListener();
    _startNewsListener();
  }

  Future<void> _initNotifications() async {
    await NotificationService().init();
  }

  void _startMatchListener() {
    _matchSub = MatchService().getMatchesStream().listen((matches) {
      if (_matchFirstLoad) {
        // Rekam state awal, jangan notif
        for (final m in matches) {
          _prevStatus[m.id] = m.status;
          _prevHome[m.id] = m.homeScore;
          _prevAway[m.id] = m.awayScore;
        }
        _matchFirstLoad = false;
        return;
      }

      for (final match in matches) {
        final prevSt = _prevStatus[match.id];
        final prevH = _prevHome[match.id] ?? 0;
        final prevA = _prevAway[match.id] ?? 0;

        if (prevSt != null) {
          // Status berubah → Live
          if (prevSt != 'Live' && match.status == 'Live') {
            NotificationService().showMatchLive(match);
          }
          // Status berubah → Finished
          else if (prevSt != 'Finished' && match.status == 'Finished') {
            NotificationService().showMatchFinished(match);
          }

          // Skor berubah saat Live → GOL
          if (match.status == 'Live' &&
              (match.homeScore != prevH || match.awayScore != prevA)) {
            NotificationService().showGoal(match, prevH, prevA);
          }
        }

        _prevStatus[match.id] = match.status;
        _prevHome[match.id] = match.homeScore;
        _prevAway[match.id] = match.awayScore;
      }
    });
  }

  void _startNewsListener() {
    _newsSub = NewsService().getNewsStream().listen((newsList) {
      if (_newsFirstLoad) {
        // Rekam ID berita paling baru saat pertama load
        _newestNewsId = newsList.isNotEmpty ? newsList.first.id : null;
        _newsFirstLoad = false;
        return;
      }

      if (newsList.isNotEmpty) {
        final latestId = newsList.first.id;
        if (latestId != _newestNewsId) {
          // Berita baru ditambahkan
          NotificationService().showNewsPublished(newsList.first.title);
          _newestNewsId = latestId;
        }
      }
    });
  }

  @override
  void dispose() {
    _matchSub.cancel();
    _newsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Pertandingan'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Berita'),
        ],
      ),
    );
  }
}
