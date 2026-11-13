import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ocr_demo/main.dart';
import 'package:ocr_demo/cubit/ocr_cubit.dart';
import 'package:ocr_demo/services/ocr_service.dart';
import 'package:ocr_demo/views/home_view.dart';

void main() {
  for (final width in [375.0, 1280.0]) {
    testWidgets('Workspace fits a $width pixel viewport', (tester) async {
      tester.view.physicalSize = Size(width, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      expect(find.text('MathLens'), findsOneWidget);
      expect(find.text('Choose PDF'), findsOneWidget);
      expect(find.text('© Mohamed Amr 2026'), findsOneWidget);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('workspace-scroll')),
      );
      final scrollable = find
          .descendant(
            of: find.byWidget(scroll),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        0,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selected file can be reset', (tester) async {
    final cubit = OcrCubit(MockOcrService());
    addTearDown(cubit.close);
    cubit.emit(
      const OcrState(status: OcrStatus.picked, fileName: 'algebra.pdf'),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: HomeView()),
      ),
    );
    expect(find.text('algebra.pdf'), findsOneWidget);
    await tester.ensureVisible(find.text('Choose another'));
    await tester.tap(find.text('Choose another'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Choose PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
