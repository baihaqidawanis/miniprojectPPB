import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String? homeTeamPhotoUrl;
  final String? awayTeamPhotoUrl;
  final DateTime matchDate;
  final int hypeCount;
  final String status;
  final String stadiumName;
  final String stadiumLocation;
  final String homeLineup;
  final String awayLineup;
  final String? homeStartingXiPhotoUrl;
  final String? awayStartingXiPhotoUrl;
  final List<dynamic> events;
  final Map<String, dynamic> stats;

  MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.homeTeamPhotoUrl,
    this.awayTeamPhotoUrl,
    required this.matchDate,
    this.hypeCount = 0,
    this.status = 'Upcoming',
    this.stadiumName = '',
    this.stadiumLocation = '',
    this.homeLineup = '',
    this.awayLineup = '',
    this.homeStartingXiPhotoUrl,
    this.awayStartingXiPhotoUrl,
    this.events = const [],
    this.stats = const {},
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      homeTeam: data['homeTeam'] ?? '',
      awayTeam: data['awayTeam'] ?? '',
      homeScore: data['homeScore'] ?? 0,
      awayScore: data['awayScore'] ?? 0,
      homeTeamPhotoUrl: data['homeTeamPhotoUrl'],
      awayTeamPhotoUrl: data['awayTeamPhotoUrl'],
      matchDate: (data['matchDate'] as Timestamp).toDate(),
      hypeCount: data['hypeCount'] ?? 0,
      status: data['status'] ?? 'Upcoming',
      stadiumName: data['stadiumName'] ?? '',
      stadiumLocation: data['stadiumLocation'] ?? '',
      homeLineup: data['homeLineup'] ?? '',
      awayLineup: data['awayLineup'] ?? '',
      homeStartingXiPhotoUrl: data['homeStartingXiPhotoUrl'],
      awayStartingXiPhotoUrl: data['awayStartingXiPhotoUrl'],
      events: data['events'] ?? [],
      stats: data['stats'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homeTeamPhotoUrl': homeTeamPhotoUrl,
      'awayTeamPhotoUrl': awayTeamPhotoUrl,
      'matchDate': Timestamp.fromDate(matchDate),
      'hypeCount': hypeCount,
      'status': status,
      'stadiumName': stadiumName,
      'stadiumLocation': stadiumLocation,
      'homeLineup': homeLineup,
      'awayLineup': awayLineup,
      'homeStartingXiPhotoUrl': homeStartingXiPhotoUrl,
      'awayStartingXiPhotoUrl': awayStartingXiPhotoUrl,
      'events': events,
      'stats': stats,
    };
  }
}
