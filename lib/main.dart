import 'package:flutter/material.dart';
import 'package:pertemuan_4/api_service.dart';
import 'package:pertemuan_4/article_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi berita',
      debugShowCheckedModeBanner: false,
      home: const BeritaScreen(),
    );
  }
}

class BeritaScreen extends StatefulWidget {
  const BeritaScreen({super.key});

  @override
  State<BeritaScreen> createState() => _BeritaScreenState();
}

class _BeritaScreenState extends State<BeritaScreen> {
  late Future<List<Article>> _articlesFuture;
  final ScrollController _scrollController = ScrollController();
  bool _showToTopButton = false;

  @override
  void initState() {
    super.initState();
    _articlesFuture = ApiService().fetchArticles();

    // Pantau posisi scroll: tombol muncul jika sudah turun > 300 piksel
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showToTopButton) {
        setState(() => _showToTopButton = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Dipanggil saat pull-to-refresh
  Future<void> _refresh() async {
    final future = ApiService().fetchArticles();
    setState(() {
      _articlesFuture = future;
    });
    try {
      await future; // indikator refresh berputar sampai data selesai dimuat
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Berita'),
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            // ListView agar pull-to-refresh tetap bisa dipakai saat error
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Terjadi kesalahan')),
                ],
              ),
            );
          }

          final articles = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return Card(
                  child: ListTile(
                    leading: article.urlToImage != null
                        ? Image.network(
                            article.urlToImage!,
                            width: 60,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.image),
                    title: Text(article.title),
                    subtitle:
                        Text(article.description ?? 'Tidak ada deskripsi'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _showToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}