import 'dart:io';

import 'package:flutter/material.dart';
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
    expect(find.text('Interior'), findsOneWidget);
    expect(find.text('Exterior'), findsOneWidget);
    expect(find.text('ESTIMATE SUMMARY'), findsOneWidget);
    expect(find.text('TOTAL ESTIMATE'), findsOneWidget);
  });

  testWidgets('Exterior tab shows description, sq ft, paint/stain, and send', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PaintEstimateApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exterior'));
    await tester.pumpAndSettle();

    expect(find.text('What is this estimate for?'), findsOneWidget);
    expect(find.text('Square Footage'), findsOneWidget);
    expect(find.text('Spindles, railings, extra'), findsOneWidget);
    expect(find.text('Linear Footage'), findsOneWidget);
    expect(find.text('Sq Ft'), findsWidgets);
    expect(find.text('Lin Ft'), findsWidgets);
    expect(find.text('Paint'), findsOneWidget);
    expect(find.text('Stain'), findsOneWidget);
    expect(find.text('Send Estimate'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('EXTERIOR ESTIMATE'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('exterior-description')), 'Front deck');
    await tester.enterText(find.byKey(const Key('exterior-sqft')), '400');
    await tester.enterText(find.byKey(const Key('exterior-extra-description')), 'Spindles');
    await tester.enterText(find.byKey(const Key('exterior-extra-sqft')), '40');
    await tester.tap(find.byKey(const Key('exterior-finish-stain')));
    await tester.pumpAndSettle();

    expect(find.text('Front deck'), findsWidgets);
    expect(find.text('Spindles'), findsWidgets);
    expect(find.textContaining('400 sq ft · Stain'), findsOneWidget);
    expect(find.textContaining('40 lin ft · Stain'), findsOneWidget);
    expect(find.textContaining('4 gal'), findsWidgets);
  });
}
