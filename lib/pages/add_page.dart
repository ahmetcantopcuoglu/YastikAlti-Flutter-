import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sınırlandırmalar için eklendi
import '../models/add_doviz_model.dart';
import '../services/kur_service.dart';
import '../services/kur_storage_service.dart';
import '../models/kur_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Giriş sayfasına yönlendirmek için

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _adetController = TextEditingController();
  final _alisController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedCode = 'USD';

  List<KurModel> altinKurlar = [];
  final storage = KurStorageService();

  final Map<String, String> kurMap = {
    'USD': 'Dolar',
    'EUR': 'Euro',
  };

  @override
  void initState() {
    super.initState();
    _loadAltinKurlar();
  }

  Future<void> _loadAltinKurlar() async {
    final kurlar = await KurService().fetchKurlar();
    setState(() {
      altinKurlar =
          kurlar.where((e) => e.code != 'USD' && e.code != 'EUR').toList();
    });
  }

  String _formatDisplayName(String rawName) {
    String lowerName = rawName.toLowerCase().replaceAll(' ', '');
    if (lowerName.contains('14ayar')) return '14 Ayar';
    if (lowerName.contains('18ayar')) return '18 Ayar';
    if (lowerName.contains('22ayar')) return '22 Ayar';
    if (lowerName.contains('ikibucuk')) return 'İki Buçuk Altın';
    if (lowerName.contains('besli')) return 'Beşli Altın';
    if (lowerName.contains('gremse')) return 'Gremse Altın';
    if (lowerName.contains('gram')) return 'Gram Altın';
    if (lowerName.contains('ceyrek') || lowerName.contains('çeyrek'))
      return 'Çeyrek Altın';
    if (lowerName.contains('yarim') || lowerName.contains('yarım'))
      return 'Yarım Altın';
    if (lowerName.contains('tam')) return 'Tam Altın';
    if (lowerName.contains('cumhuriyet')) return 'Cumhuriyet';
    if (lowerName.contains('ata')) return 'Ata Altın';
    if (lowerName.contains('resat') || lowerName.contains('reşat'))
      return 'Reşat Altın';
    if (lowerName.contains('gumus') || lowerName.contains('gümüş'))
      return 'Gümüş';

    try {
      if (rawName.isEmpty) return rawName;
      return rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
    } catch (e) {
      return rawName;
    }
  }

  void _ekle() async {

    // 1. ADIM: GİRİŞ VE LİMİT KONTROLÜ
  final currentUser = FirebaseAuth.instance.currentUser;

  // Eğer kullanıcı giriş YAPMAMIŞSA limit kontrolü yap
  if (currentUser == null) {
    int totalCount = 0;
    
    // Uygulamanızdaki tüm ana kod kategorileri
    final categories = [
      'USD', 'EUR', 'GRA', 'CEYREKALTIN', 'YARIMALTIN', 'TAMALTIN', 
      'CUMHURIYETALTINI', 'ATAALTIN', '14AYARALTIN', '18AYARALTIN', 
      '22AYARALTIN', 'IKIBUCUKALTIN', 'BESLIALTIN', 'GREMSEALTIN', 'GUMUS'
    ];

    // Her kategoriyi tek tek kontrol et ve toplam kayıt sayısını bul
    for (var code in categories) {
      final list = await storage.loadKur(code);
      totalCount += list.length;
    }

    // Toplam kayıt 3 veya daha fazlaysa durdur ve Dialog göster
    if (totalCount >= 3) {
      if (!mounted) return;
      _showLimitDialog(); // Bu fonksiyonu aşağıya ekleyeceğiz
      return;
    }
  }


    
    final adetText = _adetController.text.replaceAll(',', '.');
    final alisText = _alisController.text.replaceAll(',', '.');

    final adet = double.tryParse(adetText);
    final alis = double.tryParse(alisText);

    if (adet == null || alis == null) return;

    // --- SINIR KONTROLLERİ ---
    if (adet > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adet en fazla 9.999 olabilir!'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (alis > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Alış fiyatı en fazla 999.999 olabilir!'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Kullanıcı takvimden sadece GÜN seçse bile, biz o anki saati/dakikayı/mikrosaniyeyi ekliyoruz.
    final now = DateTime.now();
    final uniqueDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond, // Bu her kaydı eşsiz (unique) yapar
    );

    final kurlar = await KurService().fetchKurlar();
    final kur = kurlar.firstWhere((e) => e.code == selectedCode,
        orElse: () => kurlar.first);

    final newKur = EklenenKurModel(
      code: selectedCode,
      name: kur.name,
      adet: adet,
      alisKuru: alis,
      tarih: uniqueDate,
      guncelKur: kur.selling,
    );

    final eklenenler = await storage.loadKur(selectedCode);
    eklenenler.add(newKur);
    await storage.saveKur(selectedCode, eklenenler);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başarıyla eklendi!'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 500),
        ),
      );
      _adetController.clear();
      _alisController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _pickDate() async {
    final themeData = _getThemeProps(selectedCode);
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: selectedDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: themeData['color']),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Map<String, dynamic> _getThemeProps(String code) {
    if (code == 'USD') {
      return {
        'color': Colors.green.shade700,
        'gradient': [Colors.green.shade400, Colors.green.shade800],
        'icon': Icons.attach_money,
        'bgIcon': Icons.attach_money,
      };
    } else if (code == 'EUR') {
      return {
        'color': Colors.blue.shade700,
        'gradient': [Colors.blue.shade400, Colors.blue.shade800],
        'icon': Icons.euro,
        'bgIcon': Icons.euro,
      };
    } else if (code == 'GUMUS') {
      return {
        'color': Colors.blueGrey.shade600,
        'gradient': [Colors.blueGrey.shade400, Colors.blueGrey.shade800],
        'icon': Icons.circle_outlined,
        'bgIcon': Icons.layers_outlined,
      };
    } else {
      return {
        'color': Colors.amber.shade700,
        'gradient': [Colors.amber.shade400, Colors.amber.shade800],
        'icon': Icons.diamond,
        'bgIcon': Icons.blur_on,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProps = _getThemeProps(selectedCode);
    final Color mainColor = themeProps['color'];
    final List<Color> gradientColors = themeProps['gradient'];
    final IconData dynamicIcon = themeProps['icon'];
    final IconData bgIcon = themeProps['bgIcon'];

    String currentDisplayName = "";
    if (kurMap.containsKey(selectedCode)) {
      currentDisplayName = kurMap[selectedCode]!;
    } else {
      final found = altinKurlar.where((e) => e.code == selectedCode);
      currentDisplayName = found.isNotEmpty
          ? _formatDisplayName(found.first.name)
          : "Yükleniyor...";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // --- HEADER KISMI (ORİJİNAL TASARIM KORUNDU) ---
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: 60,
                            child: Icon(bgIcon,
                                size: 200,
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white30, width: 2),
                                  ),
                                  child: Icon(dynamicIcon,
                                      size: 40, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                const Text("PORTFÖYÜNE EKLE",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    currentDisplayName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedCode,
                                  decoration: _inputDecoration(
                                      "Varlık Seçimi", Icons.wallet, mainColor),
                                  isExpanded: true,
                                  items: [
                                    ...kurMap.entries.map((e) =>
                                        DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value))),
                                    ...altinKurlar.map((e) => DropdownMenuItem(
                                        value: e.code,
                                        child: Text(
                                          _formatDisplayName(e.name),
                                          overflow: TextOverflow.ellipsis,
                                        ))),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => selectedCode = val!),
                                ),
                                const SizedBox(height: 18),

                                // ADET INPUT
                                TextField(
                                  controller: _adetController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                        6), // 9.999 için limit
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*[.,]?\d*')),
                                  ],
                                  decoration: _inputDecoration(
                                      "Adet / Miktar", dynamicIcon, mainColor),
                                ),
                                const SizedBox(height: 18),

                                // ALIŞ FİYATI INPUT
                                TextField(
                                  controller: _alisController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    // Bu kural: 6 hane tam sayı, virgül/nokta sonrası 2 hane izin verir
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d{0,6}([.,]\d{0,2})?')),
                                  ],
                                  decoration: _inputDecoration(
                                      "Birim Alış Fiyatı",
                                      Icons.payments_outlined,
                                      mainColor),
                                ),
                                const SizedBox(height: 18),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded,
                                            color: mainColor, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                            "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _ekle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mainColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      elevation: 4,
                                      shadowColor: mainColor.withOpacity(0.3),
                                    ),
                                    child: const Text("Kaydet",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLimitDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber),
          SizedBox(width: 10),
          Text("Limit Doldu"),
        ],
      ),
      content: const Text(
        "Misafir kullanıcı olarak en fazla 3 kayıt ekleyebilirsiniz. "
        "Daha fazla kayıt eklemek için lütfen giriş yapın.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Dialogu kapat
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Giriş Yap / Kayıt Ol", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  InputDecoration _inputDecoration(
      String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
