import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yastikalti/main.dart';

void main() {
  testWidgets('HomePage loads correctly', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(MyApp());

    // AppBar başlığının "Ana Sayfa" olduğunu kontrol et
    expect(find.text('Ana Sayfa'), findsOneWidget);

    // BottomNavigationBar'daki butonları kontrol et
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Ekle'), findsOneWidget);
    expect(find.text('Kurlar'), findsOneWidget);
  });

  testWidgets('Navigate to AddPage and KurPage', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // AddPage'e geçiş
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Kur Ekle'), findsOneWidget);

    // KurPage'e geçiş
    await tester.tap(find.text('Kurlar'));
    await tester.pumpAndSettle();
    expect(find.text('Kurlar'), findsOneWidget);
  });
}
