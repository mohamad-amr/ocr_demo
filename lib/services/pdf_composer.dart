import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/math_correction.dart';

class WorksheetPage {
  const WorksheetPage({
    required this.png,
    required this.width,
    required this.height,
  });
  final Uint8List png;
  final int width;
  final int height;
}

class PdfBuildJob {
  const PdfBuildJob({
    required this.correction,
    required this.fileName,
    required this.pages,
    required this.font,
    required this.mono,
  });
  final MathCorrection correction;
  final String fileName;
  final List<WorksheetPage> pages;
  final ByteData font;
  final ByteData mono;

  Map<String, Object?> toMessage() => {
    'fileName': fileName,
    'font': font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes),
    'mono': mono.buffer.asUint8List(mono.offsetInBytes, mono.lengthInBytes),
    'pages': [
      for (final page in pages)
        {'png': page.png, 'width': page.width, 'height': page.height},
    ],
    'correction': {
      'summary': correction.summary,
      'problems': [
        for (final p in correction.problems)
          {
            'question': p.question,
            'studentWork': p.studentWork,
            'verdict': p.verdict,
            'explanation': p.explanation,
            'correctedSteps': p.correctedSteps,
            'marginNote': p.marginNote,
            'location': p.location == null
                ? null
                : {
                    'page': p.location!.page,
                    'box': [
                      p.location!.top * 1000,
                      p.location!.left * 1000,
                      p.location!.bottom * 1000,
                      p.location!.right * 1000,
                    ],
                  },
          },
      ],
    },
  };
}

const _ink = PdfColor.fromInt(0xFF202025);
const _muted = PdfColor.fromInt(0xFF71717A);
const _violet = PdfColor.fromInt(0xFF7257A7);
const _red = PdfColor.fromInt(0xFFB63741);
const _green = PdfColor.fromInt(0xFF267453);
const _amber = PdfColor.fromInt(0xFF9A6A25);
const _line = PdfColor.fromInt(0xFFE3E0E8);

PdfColor _verdictColor(String verdict) => switch (verdict) {
  'correct' => _green,
  'incorrect' => _red,
  _ => _amber,
};
String _verdictLabel(String verdict) => switch (verdict) {
  'correct' => 'Correct',
  'incorrect' => 'Revisit this step',
  _ => 'Needs a closer look',
};

Future<Uint8List> composeCorrectionPdf(PdfBuildJob job) async {
  final correction = job.correction;
  final fileName = job.fileName;
  final font = pw.Font.ttf(job.font);
  final mono = pw.Font.ttf(job.mono);
  final doc = pw.Document(
    title: 'Marked worksheet · $fileName',
    author: 'dev.mohamed amr',
    creator: 'MathLens',
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  var pageNumber = 0;
  final placed = <int>{};
  for (final page in job.pages) {
    pageNumber++;
    final entries = <(int, CorrectedProblem)>[];
    for (var i = 0; i < correction.problems.length; i++) {
      final problem = correction.problems[i];
      if (problem.location?.page == pageNumber) {
        entries.add((i + 1, problem));
        placed.add(i + 1);
      }
    }
    // Normalize unusual page sizes while preserving aspect ratio, including landscape.
    final scale = 842 / math.max(page.width, page.height);
    final width = page.width * scale;
    final height = page.height * scale;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width + 190, height + 108),
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header('MARKED WORKSHEET', 'PAGE $pageNumber', mono),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: width,
                  height: height,
                  child: pw.Stack(
                    children: [
                      pw.Positioned.fill(
                        child: pw.Image(
                          pw.MemoryImage(page.png),
                          fit: pw.BoxFit.fill,
                        ),
                      ),
                      ..._pageMarks(entries, width, height, mono),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.SizedBox(
                  width: 126,
                  height: height,
                  child: _marginNotes(entries, height, mono),
                ),
              ],
            ),
            pw.Spacer(),
            _footer(
              'Original page preserved · AI marks: verify before relying on them',
              mono,
            ),
          ],
        ),
      ),
    );
    // compute runs on the main event loop on web; give it time to paint
    // between source pages instead of scheduling one uninterrupted batch.
    await Future<void>.delayed(Duration.zero);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 32),
      maxPages: 100,
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 18),
        child: _header('CORRECTION NOTES', 'MATHLENS', mono),
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: _footer('AI feedback · ${context.pageNumber}', mono),
      ),
      build: (_) => [
        pw.Text(
          'A closer look at your work.',
          style: pw.TextStyle(fontSize: 24, color: _ink),
        ),
        pw.SizedBox(height: 8),
        pw.Text(fileName, style: pw.TextStyle(fontSize: 9, color: _muted)),
        pw.SizedBox(height: 18),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final verdict in ['correct', 'incorrect', 'unclear'])
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '${correction.problems.where((p) => p.verdict == verdict).length} ${switch (verdict) {
                    'correct' => 'correct',
                    'incorrect' => 'to revisit',
                    _ => 'unclear',
                  }}',
                  style: pw.TextStyle(
                    font: mono,
                    fontSize: 9,
                    color: _verdictColor(verdict),
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Paragraph(
          text: correction.summary,
          style: pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3),
        ),
        if (placed.length < correction.problems.length)
          pw.Paragraph(
            text:
                'Some answers could not be located reliably on the original pages. Their feedback is included below without an on-page mark.',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
        for (var i = 0; i < correction.problems.length; i++) ...[
          pw.NewPage(freeSpace: 180),
          pw.SizedBox(height: 12),
          pw.Header(
            level: 2,
            child: pw.Row(
              children: [
                pw.Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: pw.TextStyle(font: mono, fontSize: 12, color: _violet),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  _verdictLabel(correction.problems[i].verdict),
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: _verdictColor(correction.problems[i].verdict),
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  placed.contains(i + 1)
                      ? 'Original p. ${correction.problems[i].location!.page}'
                      : 'Notes only',
                  style: pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ),
          _paragraph('QUESTION', correction.problems[i].question, mono),
          _paragraph('YOUR WORK', correction.problems[i].studentWork, mono),
          _paragraph('FEEDBACK', correction.problems[i].explanation, mono),
          if (correction.problems[i].correctedSteps.isNotEmpty)
            pw.Text(
              'WORKED CORRECTION',
              style: pw.TextStyle(font: mono, fontSize: 8, color: _violet),
            ),
          for (final step in correction.problems[i].correctedSteps)
            pw.Paragraph(
              text: step,
              style: pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3),
            ),
        ],
      ],
    ),
  );
  return doc.save(enableEventLoopBalancing: true);
}

pw.Widget _header(String title, String right, pw.Font mono) => pw.Container(
  height: 24,
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _line)),
  ),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          font: mono,
          fontSize: 9,
          color: _ink,
          letterSpacing: 1.2,
        ),
      ),
      pw.Text(
        right,
        style: pw.TextStyle(font: mono, fontSize: 8, color: _violet),
      ),
    ],
  ),
);

pw.Widget _footer(String label, pw.Font mono) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _muted)),
    pw.Text(
      'made by dev.mohamed amr',
      style: pw.TextStyle(font: mono, fontSize: 8, color: _violet),
    ),
  ],
);

pw.Widget _paragraph(String label, String text, pw.Font mono) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      label,
      style: pw.TextStyle(font: mono, fontSize: 8, color: _muted),
    ),
    pw.SizedBox(height: 5),
    pw.Paragraph(
      text: text,
      style: pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3),
    ),
  ],
);

pw.Widget _marginNotes(
  List<(int, CorrectedProblem)> entries,
  double height,
  pw.Font mono,
) {
  final capacity = ((height - 90) / 92).floor().clamp(1, 8);
  return pw.Container(
    padding: const pw.EdgeInsets.only(left: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(left: pw.BorderSide(color: _line)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'IN THE MARGIN',
          style: pw.TextStyle(
            font: mono,
            fontSize: 8,
            color: _muted,
            letterSpacing: .5,
          ),
        ),
        pw.SizedBox(height: 18),
        if (entries.isEmpty)
          pw.Text(
            'No marks placed on this page. See the correction notes for feedback.',
            style: pw.TextStyle(fontSize: 10, color: _muted, lineSpacing: 3),
          ),
        for (final entry in entries.take(capacity))
          pw.SizedBox(
            height: 92,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${entry.$1}'.padLeft(2, '0'),
                  style: pw.TextStyle(
                    font: mono,
                    fontSize: 10,
                    color: _verdictColor(entry.$2.verdict),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  entry.$2.marginNote ?? _verdictLabel(entry.$2.verdict),
                  maxLines: 5,
                  style: pw.TextStyle(
                    font: pw.Font.timesItalic(),
                    fontSize: 12,
                    color: _verdictColor(entry.$2.verdict),
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        if (entries.length > capacity)
          pw.Text(
            'More feedback in the correction notes.',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
      ],
    ),
  );
}

List<pw.Widget> _pageMarks(
  List<(int, CorrectedProblem)> entries,
  double width,
  double height,
  pw.Font mono,
) {
  final occupied = <(double, double)>[];
  return entries.map((entry) {
    final location = entry.$2.location!;
    // Put the mark beside the work, with room for the small reference number.
    final x = (location.right * width + 3).clamp(2.0, width - 37);
    var y = (location.top * height).clamp(2.0, height - 28);
    for (var attempt = 0; attempt < entries.length; attempt++) {
      if (!occupied.any(
        (p) => (p.$1 - x).abs() < 38 && (p.$2 - y).abs() < 28,
      )) {
        break;
      }
      y = y + 29 <= height - 28 ? y + 29 : math.max(2, y - 29 * (attempt + 1));
    }
    occupied.add((x, y));
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SvgImage(svg: _penMark(entry.$2.verdict), width: 22, height: 25),
          pw.Text(
            '${entry.$1}',
            style: pw.TextStyle(
              font: mono,
              fontSize: 8,
              color: _verdictColor(entry.$2.verdict),
            ),
          ),
        ],
      ),
    );
  }).toList();
}

String _penMark(String verdict) {
  final (color, path) = switch (verdict) {
    'correct' => ('#267453', 'M 2 13 Q 5 16 8 22 Q 14 9 21 3'),
    'incorrect' => ('#B63741', 'M 4 5 Q 10 12 19 21 M 19 4 Q 11 13 4 22'),
    _ => (
      '#9A6A25',
      'M 4 7 C 5 0 19 0 18 9 C 17 13 10 13 10 18 M 10 23 L 10.1 23',
    ),
  };
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 28"><path d="$path" fill="none" stroke="$color" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
}
