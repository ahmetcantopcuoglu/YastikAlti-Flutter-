import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/add_doviz_model.dart';
import '../services/kur_storage_service.dart';

class KurDetailPage extends StatefulWidget {
  final String code;
  final String name;

  const KurDetailPage({super.key, required this.code, required this.name});

  @override
  State<KurDetailPage> createState() => _KurDetailPageState();
}

class _KurDetailPageState extends State<KurDetailPage> {
  final KurStorageService storage = KurStorageService();
  final NumberFormat tlFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  // Adet için binlik ayraçlı ama ondalıksız format
  final NumberFormat adetFormat = NumberFormat.decimalPattern('tr_TR');

  List<EklenenKurModel> eklenenler = [];
  bool isLoading = true;
  bool _isProcessing = false; 
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadKur();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  // --- KARLILIK FORMATI (HESAP MAKİNESİ TARZI) ---
  String _formatPercent(double percent) {
    double absPercent = percent.abs();
    // Eğer yüzde 4 haneyi (9999) geçerse bilimsel gösterime geç (E+)
    if (absPercent >= 10000) {
      return '%${percent.toStringAsExponential(1).toUpperCase()}';
    } 
    return '%${percent.toStringAsFixed(1)}';
  }

  String _formatDisplayName(String rawName) {
    String lowerName = rawName.toLowerCase().replaceAll(' ', '');
    if (lowerName.contains('14ayar')) return '14 Ayar Altın';
    if (lowerName.contains('18ayar')) return '18 Ayar Altın';
    if (lowerName.contains('22ayar')) return '22 Ayar Bilezik';
    if (lowerName.contains('ikibucuk')) return 'İki Buçuk Altın';
    if (lowerName.contains('besli')) return 'Beşli Altın';
    if (lowerName.contains('gremse')) return 'Gremse Altın';
    if (lowerName.contains('gram')) return 'Gram Altın';
    if (lowerName.contains('ceyrek')) return 'Çeyrek Altın';
    if (lowerName.contains('yarim') || lowerName.contains('yarım')) return 'Yarım Altın';
    if (lowerName.contains('tam')) return 'Tam Altın';
    if (lowerName.contains('cumhuriyet')) return 'Cumhuriyet Altını';
    if (lowerName.contains('ata')) return 'Ata Altın';
    if (lowerName.contains('resat') || lowerName.contains('reşat')) return 'Reşat Altın';
    if (lowerName.contains('ons')) return 'Ons Altın';
    if (lowerName.contains('has')) return 'Has Altın';
    if (lowerName.contains('gumus') || lowerName.contains('gümüş')) return 'Gümüş';
    try {
      if (rawName.isEmpty) return rawName;
      return rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
    } catch (e) { return rawName; }
  }

  Future<void> _loadKur() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    List<EklenenKurModel> list = [];

    if (widget.code == 'ALTIN') {
      final altinKodlari = ['GRA','CEYREKALTIN','YARIMALTIN','TAMALTIN',"CUMHURIYETALTINI","ATAALTIN","14AYARALTIN","18AYARALTIN","22AYARALTIN","IKIBUCUKALTIN","BESLIALTIN","GREMSEALTIN"];
      for (final code in altinKodlari) {
        final k = await storage.loadKur(code);
        list.addAll(k);
      }
    } else {
      list = await storage.loadKur(widget.code);
    }

    if (!mounted) return;
    setState(() {
      eklenenler = list;
      isLoading = false;
    });
  }

  Color _getAccentColor(EklenenKurModel item) {
    if (item.karYuzde < 0) return Colors.red.shade600;
    switch (item.code) {
      case 'USD': return Colors.green;
      case 'EUR': return Colors.blue;
      case 'GUMUS': return Colors.blueGrey;
      default: return Colors.amber;
    }
  }

  Future<void> _deleteItem(int index, EklenenKurModel item) async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() { eklenenler.removeAt(index); });
    try {
      final storedList = await storage.loadKur(item.code);
      storedList.removeWhere((e) => e.tarih.millisecondsSinceEpoch == item.tarih.millisecondsSinceEpoch);
      await storage.saveKur(item.code, storedList);
      if (mounted) { _showCountdownToast(index, item); }
    } catch (e) { debugPrint("Silme hatası: $e"); } 
    finally { _isProcessing = false; }
  }

  void _showCountdownToast(int index, EklenenKurModel item) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => _CountdownToastWidget(
        message: '${_formatDisplayName(item.name)} silindi',
        onUndo: () async {
          _overlayEntry?.remove();
          final list = await storage.loadKur(item.code);
          list.add(item);
          await storage.saveKur(item.code, list);
          if (mounted) { setState(() => eklenenler.insert(index, item)); }
        },
        onDismissed: () { _overlayEntry?.remove(); _overlayEntry = null; },
      ),
    );
    if (mounted) { Overlay.of(context).insert(_overlayEntry!); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eklenenler.isEmpty
              ? const Center(child: Text('Henüz kayıt yok', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: eklenenler.length,
                  itemBuilder: (_, i) => _buildCard(eklenenler[i], i),
                ),
    );
  }

  Widget _buildCard(EklenenKurModel item, int index) {
    final Color accentColor = _getAccentColor(item);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
      ),
      onDismissed: (_) => _deleteItem(index, item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_formatDisplayName(item.name), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          Text('${item.tarih.day}.${item.tarih.month}.${item.tarih.year}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _rowInfo('Adet', adetFormat.format(item.adet)),
                      _rowInfo('Maliyet', tlFormat.format(item.maliyet / item.adet)),
                      _rowInfo('Toplam', tlFormat.format(item.maliyet)),
                    ],
                  ),
                ),
              ),
              Container(
                width: 115, 
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('GÜNCEL', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tlFormat.format(item.guncelDeger).replaceAll('₺', '').trim(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(' ₺', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatPercent(item.karYuzde),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CountdownToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismissed;
  const _CountdownToastWidget({required this.message, required this.onUndo, required this.onDismissed});
  @override State<_CountdownToastWidget> createState() => _CountdownToastWidgetState();
}
class _CountdownToastWidgetState extends State<_CountdownToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _controller.reverse(from: 1.0);
    _controller.addStatusListener((status) { if (status == AnimationStatus.dismissed) widget.onDismissed(); });
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Positioned(
      bottom: 40, left: 20, right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF323232), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
          child: Row(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 28, height: 28, child: AnimatedBuilder(animation: _controller, builder: (_, __) => CircularProgressIndicator(value: _controller.value, strokeWidth: 2, color: Colors.amber, backgroundColor: Colors.white12))),
              AnimatedBuilder(animation: _controller, builder: (_, __) => Text((5 * _controller.value).ceil().toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 14))),
            TextButton(onPressed: widget.onUndo, child: const Text('GERİ AL', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ]),
        ),
      ),
    );
  }
}