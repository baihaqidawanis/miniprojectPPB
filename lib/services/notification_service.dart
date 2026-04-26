import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/match_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _matchChannel = AndroidNotificationDetails(
    'match_updates',
    'Update Pertandingan',
    channelDescription: 'Notifikasi live, gol, dan akhir pertandingan',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  static const _newsChannel = AndroidNotificationDetails(
    'news_updates',
    'Berita Baru',
    channelDescription: 'Notifikasi saat admin menerbitkan berita baru',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    // Minta izin notifikasi (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showMatchLive(MatchModel match) async {
    await _show(
      id: '${match.id}_live'.hashCode,
      title: '🔴 Pertandingan Sedang Berlangsung!',
      body: '${match.homeTeam} vs ${match.awayTeam} sedang berlangsung. Saksikan sekarang!',
      channel: _matchChannel,
    );
  }

  Future<void> showGoal(MatchModel match, int prevHome, int prevAway) async {
    final isHomeGoal = match.homeScore > prevHome;
    final scorer = isHomeGoal ? match.homeTeam : match.awayTeam;
    await _show(
      id: '${match.id}_goal_${match.homeScore}_${match.awayScore}'.hashCode,
      title: '⚽ GOL! $scorer mencetak gol!',
      body: '${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
      channel: _matchChannel,
    );
  }

  Future<void> showMatchFinished(MatchModel match) async {
    await _show(
      id: '${match.id}_finished'.hashCode,
      title: '🏁 Pertandingan Selesai!',
      body: 'Hasil akhir: ${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
      channel: _matchChannel,
    );
  }

  Future<void> showNewsPublished(String title) async {
    await _show(
      id: 'news_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
      title: '📰 Berita Baru!',
      body: title,
      channel: _newsChannel,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationDetails channel,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: channel),
    );
  }

  // Notifikasi terjadwal 15 menit sebelum pertandingan
  Future<void> scheduleMatchNotification(MatchModel match) async {
    if (!_initialized) await init();

    final scheduledTime = match.matchDate.subtract(const Duration(minutes: 15));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: match.id.hashCode,
      title: 'Pertandingan Segera Dimulai!',
      body: '${match.homeTeam} vs ${match.awayTeam} mulai dalam 15 menit.',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'match_reminders',
          'Pengingat Pertandingan',
          channelDescription: 'Pengingat 15 menit sebelum pertandingan',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(String matchId) async {
    await _plugin.cancel(id: matchId.hashCode);
  }
}
