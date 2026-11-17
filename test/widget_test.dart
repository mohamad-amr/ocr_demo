import 'dart:async';
import 'dart:io';
import 'package:printing/printing.dart';
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ocr_demo/main.dart';
import 'package:ocr_demo/cubit/ocr_cubit.dart';
import 'package:ocr_demo/services/gemini_ocr_service.dart';
import 'package:ocr_demo/views/home_view.dart';

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_REVIEW_ARTIFACTS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('output/ui').create(recursive: true);
    await File('output/ui/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Geist', 'GeistMono']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });
  GeminiOcrService service() => GeminiOcrService(
    request: (_) async {
      throw StateError('Widget tests must not request a correction.');
    },
  );
  for (final width in [375.0, 1280.0]) {
    testWidgets('Workspace fits a $width pixel viewport', (tester) async {
      debugDefaultTargetPlatformOverride = width > 600
          ? TargetPlatform.macOS
          : TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = Size(width, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MyApp(service: service()),
        ),
      );
      expect(find.text('MathLens'), findsOneWidget);
      expect(find.text('OCR / GEMINI'), findsOneWidget);
      expect(find.text('Choose PDF'), findsOneWidget);
      expect(find.text('© Mohamed Amr 2026'), findsOneWidget);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('page-scroll')),
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
      await capture(tester, 'upload-${width.toInt()}');
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('PDF scroll moves the page header and footer together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previous = PrintingPlatform.instance;
    final png = await tester.runAsync(
      () => File('test/fixtures/handwritten-worksheet.png').readAsBytes(),
    );
    PrintingPlatform.instance = _PreviewPrinting(png!);
    addTearDown(() => PrintingPlatform.instance = previous);
    final cubit = OcrCubit(service());
    addTearDown(cubit.close);
    cubit.emit(
      OcrState(
        status: OcrStatus.success,
        fileName: 'worksheet.pdf',
        outputBytes: Uint8List(1),
      ),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('PAGE 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Scrollable), findsOneWidget);
    final headerBefore = tester.getTopLeft(find.text('MathLens')).dy;
    final footerBefore = tester.getTopLeft(find.text('© Mohamed Amr 2026')).dy;
    expect(footerBefore, greaterThan(800));
    // Drag outside the center panel: the whole page must receive scrolling.
    await tester.dragFrom(const Offset(30, 500), const Offset(0, -400));
    await tester.pump();
    final moved = headerBefore - tester.getTopLeft(find.text('MathLens')).dy;
    expect(moved, greaterThan(100));
    expect(
      footerBefore - tester.getTopLeft(find.text('© Mohamed Amr 2026')).dy,
      closeTo(moved, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arriving PDF pages and loading completion keep reading position',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previous = PrintingPlatform.instance;
      final pages = StreamController<PdfRaster>();
      PrintingPlatform.instance = _StreamingPreviewPrinting(pages.stream);
      addTearDown(() {
        PrintingPlatform.instance = previous;
      });
      final png = await tester.runAsync(
        () => File('test/fixtures/handwritten-worksheet.png').readAsBytes(),
      );
      final cubit = OcrCubit(service());
      addTearDown(cubit.close);
      cubit.emit(
        OcrState(
          status: OcrStatus.success,
          fileName: 'worksheet.pdf',
          outputBytes: Uint8List(1),
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: HomeView()),
        ),
      );
      pages.add(_PreviewPage(png!));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.dragFrom(const Offset(30, 500), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 1));
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final offset = scroll.pixels;
      final pageTop = tester.getTopLeft(find.text('PAGE 1')).dy;
      expect(offset, greaterThan(0));
      pages.add(_PreviewPage(png));
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        expect(scroll.pixels, closeTo(offset, .1));
        expect(tester.getTopLeft(find.text('PAGE 1')).dy, closeTo(pageTop, .1));
      }
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pump();
      final bottomOffset = scroll.pixels;
      final bottomExtent = scroll.maxScrollExtent;
      unawaited(pages.close());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('End of document'), findsOneWidget);
      expect(scroll.maxScrollExtent, closeTo(bottomExtent, .1));
      expect(scroll.pixels, closeTo(bottomOffset, .1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Selected file can be reset', (tester) async {
    final cubit = OcrCubit(service());
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
  for (final width in [375.0, 1280.0]) {
    testWidgets('Loading is centered and steps fill the panel at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = OcrCubit(service());
      addTearDown(cubit.close);
      cubit.emit(
        const OcrState(status: OcrStatus.processing, fileName: 'algebra.pdf'),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark().copyWith(
                textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: 'Geist',
                ),
              ),
              home: const HomeView(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final panel = tester.getRect(
        find.byKey(const ValueKey('workspace-panel')),
      );
      final steps = tester.getRect(
        find.byKey(const ValueKey('workflow-steps')),
      );
      final icon = tester.getRect(
        find.byKey(const ValueKey('processing-icon')),
      );
      expect(steps.width, closeTo(panel.width - 2, 1));
      expect(icon.center.dx, closeTo(panel.center.dx, .5));
      expect(tester.takeException(), isNull);
      await capture(tester, 'processing-${width.toInt()}');
    });
  }
}

class _PreviewPrinting extends PrintingPlatform {
  _PreviewPrinting(this.png);
  final Uint8List png;
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    for (var i = 0; i < 3; i++) {
      yield _PreviewPage(png);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PreviewPage extends PdfRaster {
  _PreviewPage(this.png) : super(595, 842, Uint8List(0));
  final Uint8List png;
  @override
  Future<Uint8List> toPng() async => png;
  @override
  Future<ui.Image> toImage() async {
    // A small decoded raster is sufficient to exercise layout/backpressure.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 60, 85),
      Paint()..color = Colors.white,
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(60, 85);
    picture.dispose();
    return image;
  }
}

class _StreamingPreviewPrinting extends PrintingPlatform {
  _StreamingPreviewPrinting(this.pages);
  final Stream<PdfRaster> pages;
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? requestedPages,
    double dpi,
  ) => pages;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
