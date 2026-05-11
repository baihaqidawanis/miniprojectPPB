import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';
import '../providers/auth_provider.dart';
import 'admin_add_news_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  const MatchDetailScreen({required this.match});

  @override
  _MatchDetailScreenState createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MatchService _matchService = MatchService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _generateNewsWithAI(BuildContext context, MatchModel match) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    try {
      final groq = GroqService();
      final result = await groq.generateMatchNews(match);
      
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => AdminAddNewsScreen(
            initialTitle: result['title'],
            initialContent: result['content'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error AI: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _generateDummyData(MatchModel match) async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final int homePossession = 40 + (match.homeScore >= match.awayScore ? 10 : 0) + (now.millisecond % 20);
      final int awayPossession = 100 - homePossession;
      
      final stats = {
        'Penguasaan Bola': '$homePossession% - $awayPossession%',
        'Tembakan ke Gawang': '${match.homeScore + (now.millisecond % 5)} - ${match.awayScore + (now.microsecond % 5)}',
        'Pelanggaran': '${10 + (now.millisecond % 10)} - ${10 + (now.microsecond % 10)}',
        'Tendangan Sudut': '${3 + (now.millisecond % 6)} - ${3 + (now.microsecond % 6)}',
      };

      List<dynamic> events = [];
      
      for (int i = 0; i < match.homeScore; i++) {
        events.add({'minute': 10 + (i * 15) % 80, 'type': 'goal', 'team': 'home', 'player': 'Pemain Home ${i+1}'});
      }
      for (int i = 0; i < match.awayScore; i++) {
        events.add({'minute': 15 + (i * 20) % 80, 'type': 'goal', 'team': 'away', 'player': 'Pemain Away ${i+1}'});
      }
      events.add({'minute': 25 + (now.millisecond % 20), 'type': 'yellow_card', 'team': 'home', 'player': 'Bek Home'});
      events.add({'minute': 65 + (now.microsecond % 20), 'type': 'yellow_card', 'team': 'away', 'player': 'Gelandang Away'});

      events.sort((a, b) => (a['minute'] as int).compareTo(b['minute'] as int));

      await _matchService.updateMatchFields(match.id, {
        'stats': stats,
        'events': events,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data dummy berhasil dibuat!', style: TextStyle(color: Colors.black)), backgroundColor: Colors.greenAccent));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadXiPhoto(String teamType) async {
    // Tampilkan pilihan: kamera atau galeri
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Foto Starting XI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.grey.shade900,
              leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
              title: const Text('Ambil dari Kamera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.grey.shade900,
              leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
              title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final url = await _storageService.uploadStartingXiPhoto(File(picked.path), widget.match.id, teamType);
      if (url != null) {
        await _matchService.updateMatchFields(widget.match.id, {
          '${teamType}StartingXiPhotoUrl': url,
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _scanTextFromImage(TextEditingController ctrl) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Pilih Sumber Foto Lineup',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.grey.shade900,
              leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
              title: const Text('Ambil dari Kamera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.grey.shade900,
              leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
              title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isSaving = true);
    
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String currentText = ctrl.text;
      if (currentText.isNotEmpty && !currentText.endsWith('\n')) {
        currentText += '\n\n';
      }
      ctrl.text = currentText + recognizedText.text;
      
      await textRecognizer.close();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Berhasil membaca teks dari foto!', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.greenAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal membaca teks: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editLineup(String teamType, String currentLineup) async {
    final ctrl = TextEditingController(text: currentLineup);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Susunan Pemain', style: TextStyle(color: Colors.white, fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.document_scanner, color: Colors.greenAccent),
              tooltip: 'Scan dari Foto',
              onPressed: () => _scanTextFromImage(ctrl),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 12,
          decoration: InputDecoration(
            hintText: 'Contoh:\n1. Nama Kiper\n2. Nama Bek\n3. ...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              await _matchService.updateMatchFields(widget.match.id, {
                '${teamType}Lineup': ctrl.text.trim(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final isCommittee = user?.role == 'committee';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Detail Pertandingan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
      body: StreamBuilder<MatchModel?>(
        stream: _matchService.getMatchByIdStream(widget.match.id),
        builder: (context, snapshot) {
          final match = snapshot.data ?? widget.match;

          if (_isSaving) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          Color statusColor;
          if (match.status == 'Live') {
            statusColor = Colors.redAccent;
          } else if (match.status == 'Finished') {
            statusColor = Colors.grey;
          } else {
            statusColor = Colors.greenAccent;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      match.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Teams & Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamHeader(match.homeTeam, match.homeTeamPhotoUrl),
                    Column(
                      children: [
                        Text(
                          '${match.homeScore}  –  ${match.awayScore}',
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(match.matchDate),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text('${match.hypeCount} Hypes', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    _buildTeamHeader(match.awayTeam, match.awayTeamPhotoUrl),
                  ],
                ),

                // Stadium
                if (match.stadiumName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stadium, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.stadiumName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              if (match.stadiumLocation.isNotEmpty)
                                Text(match.stadiumLocation, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade800),
                const SizedBox(height: 16),

                _buildStats(match),
                _buildTimeline(match),

                // Starting XI header
                const Text(
                  'STARTING XI',
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLineupSection(context, match, 'home', isCommittee)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildLineupSection(context, match, 'away', isCommittee)),
                  ],
                ),

                if (isCommittee) ...[
                  const SizedBox(height: 32),
                  if (match.events.isEmpty)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.data_object),
                      label: const Text('GENERATE DUMMY MATCH DATA'),
                      onPressed: () => _generateDummyData(match),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('GENERATE NEWS WITH AI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    onPressed: () => _generateNewsWithAI(context, match),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(MatchModel match) {
    if (match.events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TIMELINE PERTANDINGAN', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 12),
        ...match.events.map((e) {
          final isHome = e['team'] == 'home';
          final icon = e['type'] == 'goal' ? '⚽' : (e['type'] == 'yellow_card' ? '🟨' : '🟥');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                if (isHome) Text('${e['minute']}\' $icon  ${e['player']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (!isHome) Text('${e['player']}  $icon ${e['minute']}\'', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        Divider(color: Colors.grey.shade800),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStats(MatchModel match) {
    if (match.stats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STATISTIK PERTANDINGAN', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 12),
        ...match.stats.entries.map((entry) {
          final parts = entry.value.toString().split(' - ');
          final homeVal = parts.isNotEmpty ? parts[0] : '';
          final awayVal = parts.length > 1 ? parts[1] : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(homeVal, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                Expanded(flex: 2, child: Text(entry.key, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
                Expanded(child: Text(awayVal, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        Divider(color: Colors.grey.shade800),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTeamHeader(String teamName, String? photoUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.black,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? Icon(Icons.shield, color: Colors.grey.shade700, size: 32) : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLineupSection(BuildContext context, MatchModel match, String teamType, bool isCommittee) {
    final teamName = teamType == 'home' ? match.homeTeam : match.awayTeam;
    final lineup = teamType == 'home' ? match.homeLineup : match.awayLineup;
    final xiPhotoUrl = teamType == 'home' ? match.homeStartingXiPhotoUrl : match.awayStartingXiPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // XI Formation Photo
          GestureDetector(
            onTap: isCommittee ? () => _pickAndUploadXiPhoto(teamType) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 130,
                width: double.infinity,
                color: Colors.black,
                child: xiPhotoUrl != null
                    ? Image.network(xiPhotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: isCommittee ? Colors.greenAccent : Colors.grey.shade700, size: 28),
                          if (isCommittee)
                            const Text('Tambah foto XI', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Player names
          if (lineup.isNotEmpty)
            Text(lineup, style: TextStyle(color: Colors.grey.shade300, fontSize: 12, height: 1.7))
          else
            Text(
              'Belum ada susunan pemain',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
            ),

          if (isCommittee) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _editLineup(teamType, lineup),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 4),
                  Text('Edit Susunan', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
