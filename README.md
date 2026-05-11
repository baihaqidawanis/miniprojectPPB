# miniproject_pbb

Link DEMO : https://drive.google.com/file/d/1garDrQr1CJMCZOYo71_Ba3xVvDyk-1f_/view?usp=sharing

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Fitur AI

### AI on Edge (OCR)

<img width="315" height="737" alt="Screenshot 2026-05-11 223205" src="https://github.com/user-attachments/assets/92fe5a5f-4c04-4bde-ac65-cda54ba36ab5" />


**Penjelasan:**
Fitur ini menggunakan teknologi AI yang berjalan langsung di perangkat (_on-edge_) menggunakan library `google_mlkit_text_recognition`. Aplikasi dapat mengekstrak teks dari foto susunan pemain (lineup) baik dari kamera maupun galeri. Proses ini sangat cepat dan menjaga privasi karena gambar difilter langsung oleh prosesor (_on-device_) tanpa harus dikirim ke server eksternal.

_Potongan kode implementasi:_

```dart
final inputImage = InputImage.fromFilePath(picked.path);
final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
```

### AI on Cloud (Groq API)

<img width="317" height="731" alt="Screenshot 2026-05-11 223236" src="https://github.com/user-attachments/assets/b7c6dbef-989c-4439-97fd-0b3643d3e677" />

**Penjelasan:**
Fitur ini memanfaatkan AI berbasis _cloud_ dengan terhubung ke layanan **Groq API**. Aplikasi mengirimkan _prompt_ berupa data statistik dan _timeline_ suatu pertandingan, kemudian mengandalkan LLM Cloud (seperti LLaMA yang disediakan oleh Groq) untuk menciptakan narasi draf artikel berita secara otomatis. Karena pemrosesan tidak dilakukan di hape, mekanisme ini memerlukan koneksi internet.
