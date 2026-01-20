import 'package:flutter/material.dart';
import '../models/add_doviz_model.dart';
import '../services/kur_service.dart';
import '../services/kur_storage_service.dart';
import '../models/kur_model.dart';

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
      altinKurlar = kurlar.where((e) => e.code != 'USD' && e.code != 'EUR').toList();
    });
  }

  void _ekle() async {
    final adet = double.tryParse(_adetController.text);
    final alis = double.tryParse(_alisController.text);
    if (adet == null || alis == null) return;

    final kurlar = await KurService().fetchKurlar();
    final kur = kurlar.firstWhere((e) => e.code == selectedCode, orElse: () => kurlar.first);

    final newKur = EklenenKurModel(
      code: selectedCode,
      name: kur.name,
      adet: adet,
      alisKuru: alis,
      tarih: selectedDate,
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

    // Başlıkta görünecek ismi belirle
    String currentDisplayName = "";
    if (kurMap.containsKey(selectedCode)) {
      currentDisplayName = kurMap[selectedCode]!;
    } else {
      final found = altinKurlar.where((e) => e.code == selectedCode);
      currentDisplayName = found.isNotEmpty ? found.first.name : "Yükleniyor...";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
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
                            child: Icon(bgIcon, size: 200, color: Colors.white.withOpacity(0.15)),
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
                                    border: Border.all(color: Colors.white30, width: 2),
                                  ),
                                  child: Icon(dynamicIcon, size: 40, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                const Text("PORTFÖYÜNE EKLE",
                                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                Text(
                                  currentDisplayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
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
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedCode,
                                  decoration: _inputDecoration("Varlık Seçimi", Icons.wallet, mainColor),
                                  items: [
                                    ...kurMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                                    ...altinKurlar.map((e) => DropdownMenuItem(value: e.code, child: Text(e.name))),
                                  ],
                                  onChanged: (val) => setState(() => selectedCode = val!),
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _adetController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration("Adet / Miktar", dynamicIcon, mainColor),
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _alisController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration("Alış Fiyatı (Birim)", Icons.payments_outlined, mainColor),
                                ),
                                const SizedBox(height: 18),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, color: mainColor, size: 20),
                                        const SizedBox(width: 12),
                                        Text("${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 4,
                                      shadowColor: mainColor.withOpacity(0.3),
                                    ),
                                    child: const Text("Kaydet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  InputDecoration _inputDecoration(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}