import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kur_model.dart';
import '../services/kur_service.dart';

class KurPage extends StatefulWidget {
  const KurPage({super.key});

  @override
  State<KurPage> createState() => _KurPageState();
}

class _KurPageState extends State<KurPage> {
  late Future<List<KurModel>> futureKurlar;

  @override
  void initState() {
    super.initState();
    _refreshKurlar();
  }

  void _refreshKurlar() {
    setState(() {
      futureKurlar = KurService().fetchKurlar();
    });
  }

  /// İsimleri düzelten yardımcı fonksiyon (Boşluk sorununu çözer)
  String _fixName(String code, String rawName) {
    String lowerName = rawName.toLowerCase();
    
    // Altın türleri için özel düzeltmeler
    if (lowerName.contains('ceyrek') || lowerName.contains('çeyrek')) return 'Çeyrek Altın';
    if (lowerName.contains('gram') && lowerName.contains('altin')) return 'Gram Altın';
    if (lowerName.contains('yarim') || lowerName.contains('yarım')) return 'Yarım Altın';
    if (lowerName.contains('tam') && lowerName.contains('altin')) return 'Tam Altın';
    if (lowerName.contains('cumhuriyet')) return 'Cumhuriyet Altını';
    if (lowerName.contains('gumus') || lowerName.contains('gümüş')) return 'Gümüş';
    if (code == 'GA') return 'Gram Altın';
    if (code == 'C') return 'Çeyrek Altın';

    // Eğer özel bir durum yoksa gelen ismin baş harflerini büyütüp döndür
    return rawName; 
  }

  /// Renk, İkon ve Görünen İsim Ayarları
  Map<String, dynamic> _getThemeProps(String code, String name) {
    String lowerName = name.toLowerCase();
    
    // Altın kontrolü (Daha geniş kapsamlı)
    bool isGold = (code == 'GA' || code == 'C' || code == 'Y' || code == 'T' || 
                   lowerName.contains('altın') || lowerName.contains('altin') || 
                   lowerName.contains('ceyrek') || lowerName.contains('ziynet'));
                   
    // Gümüş kontrolü
    bool isSilver = lowerName.contains('gümüş') || lowerName.contains('gumus') || code == 'GUMUS';

    if (code == 'USD') {
      return {
        'color': Colors.green.shade800,
        'lightColor': Colors.green.shade50,
        'icon': Icons.attach_money,
        'displayName': 'USD', 
      };
    } else if (code == 'EUR') {
      return {
        'color': Colors.blue.shade800,
        'lightColor': Colors.blue.shade50,
        'icon': Icons.euro,
        'displayName': 'EUR',
      };
    } else if (isGold) {
      return {
        'color': const Color(0xFFFFB300), // Canlı Amber Rengi
        'lightColor': const Color(0xFFFFF8E1), // Çok açık amber arka plan
        'icon': Icons.diamond_outlined, // Altın için elmas ikonu
        'displayName': _fixName(code, name), // İsmi düzelt
      };
    } else if (isSilver) {
      return {
        'color': const Color(0xFF607D8B), // Metalik Gri (BlueGrey)
        'lightColor': const Color(0xFFECEFF1),
        'icon': Icons.circle_outlined,
        'displayName': 'Gümüş',
      };
    } else {
      // Diğer Dövizler
      return {
        'color': const Color(0xFF2E3192),
        'lightColor': const Color(0xFFE8EAF6),
        'icon': Icons.currency_exchange,
        'displayName': code, // Diğerlerinde sadece kodu göster (GBP, CHF vb.)
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          // --- HEADER KISMI ---
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F9D58), Color(0xFF00ACC1)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.show_chart,
                    size: 180,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CANLI TAKİP",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Piyasalar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await KurService().forceRefresh();
                            _refreshKurlar();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(Icons.refresh, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- LİSTE KISMI ---
          Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.18),
            child: FutureBuilder<List<KurModel>>(
              future: futureKurlar,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Text('Hata oluştu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Veri bulunamadı"));
                }

                final kurlar = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => _refreshKurlar(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                    itemCount: kurlar.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCompactKurCard(kurlar[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactKurCard(KurModel kur) {
    // Tema özelliklerini al
    final theme = _getThemeProps(kur.code, kur.name);
    
    final Color mainColor = theme['color'];
    final Color lightBg = theme['lightColor'];
    final IconData icon = theme['icon'];
    final String displayName = theme['displayName'];

    return Container(
      height: 68, // Sabit yükseklik
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Sol Renk Çubuğu
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // 2. İkon ve İsim
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: lightBg,
                      shape: BoxShape.circle, // Daire şeklinde ikon arka planı
                    ),
                    child: Icon(icon, color: mainColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fiyatlar
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPriceItem("ALIŞ", kur.buying, Colors.green.shade700),
                  ),
                  // Araya ince çizgi
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildPriceItem("SATIŞ", kur.selling, Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, double? price, Color color) {
    // Null safety kontrolü (fiyat null gelirse 0.00 göster)
    double safePrice = price ?? 0.00;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                safePrice.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'RobotoMono', 
                ),
              ),
              const SizedBox(width: 2),
              Text(
                "₺",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}