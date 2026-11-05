import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Song Player App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNavigationScreen(),
    );
  }
}

// ==========================================
// 1. NAVIGASI UTAMA
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchSongScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Cari Lagu',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ==========================================
// 2. HALAMAN PENCARIAN LAGU
// ==========================================
class SearchSongScreen extends StatefulWidget {
  const SearchSongScreen({super.key});

  @override
  State<SearchSongScreen> createState() => _SearchSongScreenState();
}

class _SearchSongScreenState extends State<SearchSongScreen> {
  final controller = TextEditingController();
  List songs = [];
  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> findSong() async {
    final term = controller.text.trim();
    if (term.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.https('itunes.apple.com', '/search', {
        'term': term,
        'entity': 'song',
        'limit': '15',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          songs = data['results'];
        });
      } else {
        debugPrint('Request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Player & Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Search song or artist',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: findSong,
                ),
              ),
              onSubmitted: (_) => findSong(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : songs.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada lagu atau hasil pencarian kosong.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: song['artworkUrl100'] != null
                                ? Image.network(
                                    song['artworkUrl100'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.music_note),
                            title: Text(song['trackName'] ?? ''),
                            subtitle: Text(song['artistName'] ?? ''),
                            trailing: const Icon(
                              Icons.play_arrow,
                              color: Colors.blue,
                            ),
                            onTap: () {
                              // Navigasi ke Halaman Pemutar Musik
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlayerDetailScreen(song: song),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. HALAMAN PEMUTAR MUSIK
// ==========================================
class PlayerDetailScreen extends StatelessWidget {
  final Map song;

  const PlayerDetailScreen({super.key, required this.song});

  Future<void> _playMusicPreview(
    BuildContext context,
    String? previewUrl,
  ) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maaf, preview musik tidak tersedia.')),
      );
      return;
    }

    final Uri uri = Uri.parse(previewUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka pemutar musik.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artworkUrl =
        song['artworkUrl100']?.replaceAll('100x100bb', '600x600bb') ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Pemutar Musik')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: artworkUrl.isNotEmpty
                  ? Image.network(
                      artworkUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 220,
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 80),
                    ),
            ),
            const SizedBox(height: 30),
            Text(
              song['trackName'] ?? 'Judul Tidak Diketahui',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              song['artistName'] ?? 'Artis Tidak Diketahui',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _playMusicPreview(context, song['previewUrl']),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Putar Preview (30 Detik)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. HALAMAN PROFIL PENGGUNA
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mahasiswa Sistem Informasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Universitas Tarumanagara',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 40, thickness: 1),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email Kampus'),
                subtitle: const Text('mahasiswa@stu.untar.ac.id'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Tentang Aplikasi'),
                subtitle: const Text(
                  'Aplikasi Pemutar Musik Flutter berbasis iTunes API.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
