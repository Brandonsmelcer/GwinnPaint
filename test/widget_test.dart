import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:paint_estimate_calculator/main.dart';
import 'package:paint_estimate_calculator/services/estimate_storage_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    await EstimateStorageService.init();
  });

  testWidgets('Paint estimate screen renders brand header', (WidgetTester tester) async {
    await tester.pumpWidget(const PaintEstimateApp());
    await tester.pumpAndSettle();

    expect(find.text('GWINN'), findsOneWidget);
    expect(find.text('ESTIMATE SUMMARY'), findsOneWidget);
    expect(find.text('TOTAL ESTIMATE'), findsOneWidget);
  });
}
