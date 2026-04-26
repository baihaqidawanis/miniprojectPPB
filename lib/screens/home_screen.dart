import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import 'admin_add_match_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final MatchService _matchService = MatchService();

  // Tampilkan bottom sheet login admin
  void _showAdminLoginSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.userModel?.role == 'committee';

    if (isAdmin) {
      // Sudah login sebagai admin → tawarkan logout
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _AdminLogoutSheet(auth: auth),
      );
    } else {
      // Belum login sebagai admin → tampilkan login form
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _AdminLoginSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final isAdmin = user?.role == 'committee';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'MATCH TRACKER',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showAdminLoginSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdmin ? Colors.greenAccent : Colors.grey.shade700,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                      color: isAdmin ? Colors.greenAccent : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAdmin ? 'Admin' : 'Guest',
                      style: TextStyle(
                        color: isAdmin ? Colors.greenAccent : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAddMatchScreen())),
            )
          : null,
      body: StreamBuilder<List<MatchModel>>(
        stream: _matchService.getMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ada kesalahan: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final matches = snapshot.data;
          if (matches == null || matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade800),
                  const SizedBox(height: 16),
                  const Text('Belum ada jadwal pertandingan.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) => _buildMatchCard(context, matches[index], user),
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match, var user) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(match.matchDate);

    Color statusColor;
    if (match.status == 'Live') {
      statusColor = Colors.redAccent;
    } else if (match.status == 'Finished') {
      statusColor = Colors.grey;
    } else {
      statusColor = Colors.greenAccent;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match))),
      child: Card(
        color: Colors.grey.shade900,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          match.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (user != null && user.role == 'committee') ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Pertandingan?'),
                                content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _matchService.deleteMatch(match);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pertandingan berhasil dihapus')),
                              );
                            }
                          },
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showEditMatchDialog(context, match),
                          child: const Icon(Icons.edit, color: Colors.amber),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTeamColumn(match.homeTeam, match.homeTeamPhotoUrl),
                  Column(
                    children: [
                      Text(
                        '${match.homeScore} - ${match.awayScore}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text('${match.hypeCount} Hypes', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  _buildTeamColumn(match.awayTeam, match.awayTeamPhotoUrl),
                ],
              ),
              if (match.stadiumName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stadium, color: Colors.grey, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      match.stadiumLocation.isNotEmpty
                          ? '${match.stadiumName} · ${match.stadiumLocation}'
                          : match.stadiumName,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String teamName, String? photoUrl) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? Icon(Icons.shield, color: Colors.grey.shade800, size: 24) : null,
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade900,
        highlightColor: Colors.grey.shade800,
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _showEditMatchDialog(BuildContext context, MatchModel match) async {
    final homeScoreCtrl = TextEditingController(text: match.homeScore.toString());
    final awayScoreCtrl = TextEditingController(text: match.awayScore.toString());
    String selectedStatus = match.status;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Edit Pertandingan', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: homeScoreCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Skor Home',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: awayScoreCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Skor Away',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                ),
                items: ['Upcoming', 'Live', 'Finished']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedStatus = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              onPressed: () async {
                await _matchService.updateScoreStatus(
                  match.id,
                  int.tryParse(homeScoreCtrl.text) ?? match.homeScore,
                  int.tryParse(awayScoreCtrl.text) ?? match.awayScore,
                  selectedStatus,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet: Admin Login
// ─────────────────────────────────────────────
class _AdminLoginSheet extends StatefulWidget {
  const _AdminLoginSheet();

  @override
  State<_AdminLoginSheet> createState() => _AdminLoginSheetState();
}

class _AdminLoginSheetState extends State<_AdminLoginSheet> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _doLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Login admin berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${auth.errorMessage}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Masuk untuk mengelola pertandingan',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Email field
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email Admin',
              labelStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.greenAccent, size: 20),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.greenAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          // Password field
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.greenAccent, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.greenAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _doLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('MASUK SEBAGAI ADMIN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet: Admin Logout Confirmation
// ─────────────────────────────────────────────
class _AdminLogoutSheet extends StatelessWidget {
  final AuthProvider auth;
  const _AdminLogoutSheet({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode Admin Aktif',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    auth.userModel?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Kamu punya akses penuh untuk CRUD data pertandingan.',
                  style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('KELUAR DARI MODE ADMIN'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await auth.logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
