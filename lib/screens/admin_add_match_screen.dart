import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/match_model.dart';
import '../services/match_service.dart';

class AdminAddMatchScreen extends StatefulWidget {
  @override
  _AdminAddMatchScreenState createState() => _AdminAddMatchScreenState();
}

class _AdminAddMatchScreenState extends State<AdminAddMatchScreen> {
  final _homeTeamCtrl = TextEditingController();
  final _awayTeamCtrl = TextEditingController();
  final _stadiumNameCtrl = TextEditingController();
  final _stadiumLocationCtrl = TextEditingController();
  DateTime? _matchDate;

  File? _homeImage;
  File? _awayImage;

  final ImagePicker _picker = ImagePicker();
  final MatchService _matchService = MatchService();
  bool _isLoading = false;

  Future<void> _pickImage(String team) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.greenAccent),
              title: Text('Ambil dari Kamera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) {
                  setState(() {
                    if (team == 'home') _homeImage = File(picked.path);
                    else _awayImage = File(picked.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.greenAccent),
              title: Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) {
                  setState(() {
                    if (team == 'home') _homeImage = File(picked.path);
                    else _awayImage = File(picked.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_homeTeamCtrl.text.isEmpty || _awayTeamCtrl.text.isEmpty || _matchDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi nama tim & tanggal')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      MatchModel newMatch = MatchModel(
        id: '',
        homeTeam: _homeTeamCtrl.text.trim(),
        awayTeam: _awayTeamCtrl.text.trim(),
        matchDate: _matchDate!,
        status: 'Upcoming',
        stadiumName: _stadiumNameCtrl.text.trim(),
        stadiumLocation: _stadiumLocationCtrl.text.trim(),
      );

      await _matchService.createMatch(newMatch, homeImage: _homeImage, awayImage: _awayImage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pertandingan berhasil ditambahkan!')),
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
        title: Text('Tambah Pertandingan'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTeamInput('Tim Tuan Rumah (Home)', _homeTeamCtrl, 'home', _homeImage),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ),
                  const SizedBox(height: 24),
                  _buildTeamInput('Tim Tamu (Away)', _awayTeamCtrl, 'away', _awayImage),
                  const SizedBox(height: 24),

                  // Stadium section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stadium, color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 8),
                            Text('Info Stadion', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _stadiumNameCtrl,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nama Stadion',
                            hintText: 'contoh: Gelora Bung Tomo',
                            labelStyle: TextStyle(color: Colors.grey),
                            hintStyle: TextStyle(color: Colors.grey.shade700),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _stadiumLocationCtrl,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Lokasi',
                            hintText: 'contoh: Surabaya, Indonesia',
                            labelStyle: TextStyle(color: Colors.grey),
                            hintStyle: TextStyle(color: Colors.grey.shade700),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    tileColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(Icons.calendar_today, color: Colors.greenAccent),
                    title: Text(
                      _matchDate == null
                          ? 'Pilih Tanggal & Waktu'
                          : '${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year}  ${_matchDate!.hour.toString().padLeft(2, '0')}:${_matchDate!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null && mounted) {
                        TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _matchDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
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
                    child: Text('SIMPAN PERTANDINGAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamInput(String label, TextEditingController controller, String teamType, File? image) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Logo Club (Opsional)', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(teamType),
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
                image: image != null ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) : null,
                border: Border.all(color: Colors.grey.shade800, width: 2),
              ),
              child: image == null
                  ? Center(child: Icon(Icons.add_a_photo, color: Colors.greenAccent, size: 32))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
