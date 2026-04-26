import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import 'storage_service.dart';
import 'dart:io';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<void> createMatch(MatchModel match, {File? homeImage, File? awayImage}) async {
    try {
      DocumentReference docRef = _firestore.collection('matches').doc();
      String matchId = docRef.id;

      String? homePhotoUrl;
      String? awayPhotoUrl;
      if (homeImage != null) {
        homePhotoUrl = await _storageService.uploadTeamPhoto(homeImage, matchId, 'home');
      }
      if (awayImage != null) {
        awayPhotoUrl = await _storageService.uploadTeamPhoto(awayImage, matchId, 'away');
      }

      MatchModel finalMatch = MatchModel(
        id: matchId,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        matchDate: match.matchDate,
        homeTeamPhotoUrl: homePhotoUrl,
        awayTeamPhotoUrl: awayPhotoUrl,
        hypeCount: 0,
        status: match.status,
        stadiumName: match.stadiumName,
        stadiumLocation: match.stadiumLocation,
      );

      await docRef.set(finalMatch.toMap());
    } catch (e) {
      print("Error creating match: $e");
      rethrow;
    }
  }

  Stream<List<MatchModel>> getMatchesStream() {
    return _firestore
        .collection('matches')
        .orderBy('matchDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList());
  }

  Stream<MatchModel?> getMatchByIdStream(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  Future<void> updateScoreStatus(String matchId, int homeScore, int awayScore, String status) async {
    await _firestore.collection('matches').doc(matchId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
    });
  }

  Future<void> updateMatchFields(String matchId, Map<String, dynamic> fields) async {
    await _firestore.collection('matches').doc(matchId).update(fields);
  }

  Future<void> deleteMatch(MatchModel match) async {
    try {
      if (match.homeTeamPhotoUrl != null) {
        await _storageService.deleteByUrl(match.homeTeamPhotoUrl!);
      }
      if (match.awayTeamPhotoUrl != null) {
        await _storageService.deleteByUrl(match.awayTeamPhotoUrl!);
      }
      await _firestore.collection('matches').doc(match.id).delete();
    } catch (e) {
      print("Error deleting match: $e");
    }
  }
}
