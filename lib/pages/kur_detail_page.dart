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
  final NumberFormat tlFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  List<EklenenKurModel> eklenenler = [];
  bool isLoading = true;
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

  Future<void> _loadKur() async {
    setState(() => isLoading = true);
    List<EklenenKurModel> list = [];

    if (widget.code == 'ALTIN') {
      final altinKodlari = [
        'GRA',
        'CEYREKALTIN',
        'YARIMALTIN',
        'TAMALTIN',
        'GUMUS'
      ];
      for (final code in altinKodlari) {
        final k = await storage.loadKur(code);
        list.addAll(k);
      }
    } else {
      list = await storage.loadKur(widget.code);
    }

    setState(() {
      eklenenler = list;
      isLoading = false;
    });
  }

  // ==================== RENK MANTIĞI ====================
  Color _getAccentColor(EklenenKurModel item) {
    // Zararda ise HER ZAMAN kırmızı
    if (item.karYuzde < 0) {
      return Colors.red.shade600;
    }

    // Kârlıysa ürüne göre renk
    switch (item.code) {
      case 'USD':
        return Colors.green;
      case 'EUR':
        return Colors.blue;
      case 'ALTIN':
      case 'GRA':
      case 'CEYREKALTIN':
      case 'YARIMALTIN':
      case 'TAMALTIN':
        return Colors.amber;
      default:
        return Colors.green.shade600;
    }
  }
  // =====================================================

  Future<void> _deleteItem(int index, EklenenKurModel item) async {
    setState(() => eklenenler.removeAt(index));

    final storedList = await storage.loadKur(item.code);
    storedList.removeWhere((e) =>
        e.tarih.millisecondsSinceEpoch ==
        item.tarih.millisecondsSinceEpoch);
    await storage.saveKur(item.code, storedList);

    _showCountdownToast(index, item);
  }

  void _showCountdownToast(int index, EklenenKurModel item) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => _CountdownToastWidget(
        message: '${item.name} silindi',
        onUndo: () async {
          _overlayEntry?.remove();
          _overlayEntry = null;
          final list = await storage.loadKur(item.code);
          list.add(item);
          await storage.saveKur(item.code, list);
          setState(() => eklenenler.insert(index, item));
        },
        onDismissed: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(widget.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eklenenler.isEmpty
              ? const Center(
                  child: Text('Henüz kayıt yok',
                      style: TextStyle(color: Colors.grey)))
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
      key: ValueKey(item.tarih.millisecondsSinceEpoch),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Silinsin mi?'),
            content:
                Text('${item.name} kaydını silmek istiyor musunuz?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('İptal')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sil',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteItem(index, item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${item.tarih.day}.${item.tarih.month}.${item.tarih.year}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _rowInfo('Adet', item.adet.toString()),
                      _rowInfo('Maliyet',
                          tlFormat.format(item.maliyet / item.adet)),
                      _rowInfo(
                          'Toplam', tlFormat.format(item.maliyet)),
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('GÜNCEL',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text(
                      tlFormat
                          .format(item.guncelDeger)
                          .replaceAll('₺', ''),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(
                          '%${item.karYuzde.toStringAsFixed(1)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
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
          style:
              const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.grey)),
            TextSpan(
                text: value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ================== OVERLAY TOAST ==================
class _CountdownToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismissed;

  const _CountdownToastWidget(
      {required this.message,
      required this.onUndo,
      required this.onDismissed});

  @override
  State<_CountdownToastWidget> createState() =>
      _CountdownToastWidgetState();
}

class _CountdownToastWidgetState extends State<_CountdownToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _controller.reverse(from: 1.0);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF323232),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) =>
                          CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 2,
                        color: Colors.amber,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Text(
                      (5 * _controller.value).ceil().toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.message,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
              ),
              TextButton(
                onPressed: widget.onUndo,
                child: const Text('GERİ AL',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
