import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match_model.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, String>> generateMatchNews(MatchModel match) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Groq API Key tidak ditemukan. Pastikan sudah diset di file .env');
    }

    String timelineStr = 'Tidak ada data timeline.';
    if (match.events.isNotEmpty) {
      timelineStr = match.events.map((e) {
        String eventName = e['type'] == 'goal' ? 'Gol' : (e['type'] == 'yellow_card' ? 'Kartu Kuning' : 'Kartu Merah');
        return "Menit ${e['minute']}: $eventName oleh ${e['player']} (Tim: ${e['team'] == 'home' ? match.homeTeam : match.awayTeam})";
      }).join('\n');
    }

    String statsStr = 'Tidak ada data statistik.';
    if (match.stats.isNotEmpty) {
      statsStr = match.stats.entries.map((e) => "${e.key}: ${e.value} (Home - Away)").join('\n');
    }

    final prompt = '''
Buatkan artikel berita olahraga yang dramatis, menarik, profesional, dan SEO-friendly untuk pertandingan berikut:
Tim Tuan Rumah: ${match.homeTeam}
Tim Tamu: ${match.awayTeam}
Skor Akhir: ${match.homeScore} - ${match.awayScore}
Stadion: ${match.stadiumName}
Tanggal Pertandingan: ${match.matchDate.toString()}

STATISTIK PERTANDINGAN:
$statsStr

TIMELINE KEJADIAN PENTING:
$timelineStr

Tugas Anda:
1. Buat judul artikel yang bombastis dan menarik perhatian pembaca.
2. Tulis isi berita minimal 3 paragraf. Paragraf pertama berisi ringkasan hasil pertandingan. Paragraf kedua dan ketiga menceritakan jalannya pertandingan secara dramatis berdasarkan STATISTIK dan TIMELINE di atas. Sebutkan nama-nama pencetak gol dan kejadian penting (kartu kuning/merah).
3. Kembalikan DALAM FORMAT JSON DENGAN DUA KEY: "title" dan "content".
4. Pastikan format JSON benar (valid JSON).
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "Anda adalah seorang jurnalis olahraga profesional dari Indonesia yang selalu mengembalikan respon dalam format JSON."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String jsonContent = data['choices'][0]['message']['content'];
        final Map<String, dynamic> result = jsonDecode(jsonContent);
        
        return {
          'title': result['title'] ?? 'Berita Pertandingan',
          'content': result['content'] ?? 'Isi berita gagal di-*generate*.',
        };
      } else {
        throw Exception('Gagal menghubungi Groq API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error GroqService: $e');
    }
  }
}
