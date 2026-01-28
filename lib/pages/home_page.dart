import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/kur_storage_service.dart';
import '../models/add_doviz_model.dart';
import 'add_page.dart';
import 'kur_detail_page.dart';
import 'kur_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  User? _currentUser;
  String? _userName;

  final List<Widget> _pages = const [
    HomeTab(),
    AddPage(),
    KurPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    if (_currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .get();

    final data = doc.data();
    print("USER DATA: $data");

    if (data == null) return;

    setState(() {
      _userName = data['full_name'] ??
          data['name'] ??
          data['username'] ??
          data['email'] ??
          'Kullanıcı';
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'YASTIK ALTI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        
        // 🔹 GÜNCELLENEN KISIM BAŞLIYOR 🔹
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () async {
              // Giriş yoksa → direkt login sayfasına git
              if (_currentUser == null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );

                // Login sayfasından dönünce kullanıcıyı tekrar kontrol et
                _currentUser = FirebaseAuth.instance.currentUser;
                await _loadUserName();
                return;
              }

              // Giriş varsa → Profil menüsünü aç
              final selected = await showMenu<String>(
                context: context,
                // Menünün açılacağı konumu ayarlıyoruz
                position: const RelativeRect.fromLTRB(1000, 80, 8, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Menü kenarları yuvarlatıldı
                ),
                items: [
                  // --- 1. SEÇENEK TASARIMI (Profil Kartı) ---
                  PopupMenuItem<String>(
                    enabled: false, // Tıklanamaz, sadece bilgi gösterir
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Avatar (Baş harf)
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
                            radius: 20,
                            child: Text(
                              (_userName != null && _userName!.isNotEmpty)
                                  ? _userName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Color(0xFF2E7D32), 
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // İsim
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _userName ?? 'Kullanıcı',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  "Hesabım",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(), // Araya çizgi
                  
                  // Çıkış Yap Butonu
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: Colors.redAccent, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              // Seçilen işleme göre aksiyon al
              if (selected == 'logout') {
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _currentUser = null;
                  _userName = null; // İsmi de sıfırla
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        // 🔹 GÜNCELLENEN KISIM BİTTİ 🔹
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Varlıklar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Piyasalar',
          ),
        ],
      ),
    );
  }
}

// --- ALTTAKİ TAB CLASSLARI DEĞİŞMEDİ ---

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final KurStorageService storage = KurStorageService();

  final NumberFormat tlFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  final NumberFormat profitFormat = NumberFormat('#,##0', 'tr_TR');

  String formatRate(double rate) {
    if (rate.abs() >= 100000) {
      return rate.toStringAsExponential(2);
    } else {
      return rate.toStringAsFixed(2);
    }
  }

  Future<Map<String, double>> _calculateTotals(String code) async {
    List<EklenenKurModel> list = [];
    if (code == 'ALTIN') {
      final altinKodlari = [
        'GRA',
        'CEYREKALTIN',
        'YARIMALTIN',
        'TAMALTIN',
        "CUMHURIYETALTINI",
        "ATAALTIN",
        "14AYARALTIN",
        "18AYARALTIN",
        "22AYARALTIN",
        "IKIBUCUKALTIN",
        "BESLIALTIN",
        "GREMSEALTIN",
        'GUMUS',
      ];
      for (final c in altinKodlari) {
        list.addAll(await storage.loadKur(c));
      }
    } else {
      list = await storage.loadKur(code);
    }

    double total = 0;
    double profit = 0;
    for (final item in list) {
      total += item.guncelDeger;
      profit += (item.guncelDeger - item.maliyet);
    }

    double totalCost = total - profit;
    double rate = totalCost > 0 ? (profit / totalCost) * 100 : 0;

    return {'total': total, 'profit': profit, 'rate': rate};
  }

  Future<Map<String, double>> _calculateGrandTotal() async {
    double grandTotal = 0;
    double grandProfit = 0;
    final categories = ['USD', 'EUR', 'ALTIN'];

    for (final cat in categories) {
      final result = await _calculateTotals(cat);
      grandTotal += result['total']!;
      grandProfit += result['profit']!;
    }

    double totalCost = grandTotal - grandProfit;
    double rate = totalCost > 0 ? (grandProfit / totalCost) * 100 : 0;

    return {'total': grandTotal, 'profit': grandProfit, 'rate': rate};
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'code': 'USD', 'name': 'Dolar', 'color': Colors.green, 'icon': Icons.attach_money},
      {'code': 'EUR', 'name': 'Euro', 'color': Colors.blue, 'icon': Icons.euro},
      {'code': 'ALTIN', 'name': 'Altın', 'color': Colors.amber, 'icon': Icons.blur_on},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...categories.map((cat) {
          return FutureBuilder<Map<String, double>>(
            future: _calculateTotals(cat['code'] as String),
            builder: (context, snapshot) {
              final data = snapshot.data ?? {'total': 0, 'profit': 0, 'rate': 0};
              final total = data['total']!;
              final profit = data['profit']!;
              final rate = data['rate']!;
              final isPositive = profit >= 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KurDetailPage(
                        code: cat['code'] as String,
                        name: cat['name'] as String,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [(cat['color'] as Color).withOpacity(0.85), cat['color'] as Color],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: (cat['color'] as Color).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 120,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cat['name'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                                  child: Text(
                                    cat['code'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text("Toplam Bakiye", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              tlFormat.format(total),
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${isPositive ? '+' : ''}${profitFormat.format(profit)} ₺",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const VerticalDivider(color: Colors.white24, width: 20, thickness: 1),
                                  Text(
                                    "%${formatRate(rate)}",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
        FutureBuilder<Map<String, double>>(
          future: _calculateGrandTotal(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {'total': 0, 'profit': 0, 'rate': 0};
            final total = data['total']!;
            final profit = data['profit']!;
            final rate = data['rate']!;
            final isPositive = profit >= 0;

            return Container(
              margin: const EdgeInsets.only(top: 24, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF263238), Color(0xFF37474F)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Toplam Net Varlık", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        tlFormat.format(total),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${isPositive ? '+' : ''}${profitFormat.format(profit)} ₺",
                            style: TextStyle(
                              color: isPositive ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "%${formatRate(rate)}",
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}