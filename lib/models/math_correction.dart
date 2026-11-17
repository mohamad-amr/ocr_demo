import 'dart:convert';

class MathCorrection {
  const MathCorrection({required this.summary, required this.problems});
  final String summary;
  final List<CorrectedProblem> problems;

  factory MathCorrection.parse(String source) {
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic> || data['problems'] is! List) {
      throw const FormatException('Invalid correction structure.');
    }
    final items = data['problems'] as List;
    if (items.length > 30) throw const FormatException('Too many problems.');
    return MathCorrection(
      summary: _text(data['summary']),
      problems: items.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid problem.');
        }
        final verdict = _text(item['verdict']);
        if (!['correct', 'incorrect', 'unclear'].contains(verdict)) {
          throw const FormatException('Invalid verdict.');
        }
        final steps = item['correctedSteps'];
        if (steps is! List || steps.length > 50) {
          throw const FormatException('Invalid steps.');
        }
        return CorrectedProblem(
          question: _text(item['question']),
          studentWork: _text(item['studentWork']),
          verdict: verdict,
          explanation: _text(item['explanation']),
          correctedSteps: steps.map(_text).toList(),
          location: ProblemLocation.tryParse(item['location']),
          marginNote: _marginNote(item['marginNote']),
        );
      }).toList(),
    );
  }

  static String _text(Object? value) {
    if (value is! String || value.trim().isEmpty || value.length > 12000) {
      throw const FormatException('Invalid correction text.');
    }
    return value.trim();
  }

  static String? _marginNote(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final text = value.trim();
    return text.length <= 100 ? text : '${text.substring(0, 97)}...';
  }
}

/// Normalized page coordinates, measured from the top-left of the PDF page.
/// Uncertain or malformed locations are omitted rather than guessed.
class ProblemLocation {
  const ProblemLocation({
    required this.page,
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });
  final int page;
  final double top;
  final double left;
  final double bottom;
  final double right;

  static ProblemLocation? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final page = value['page'];
    final box = value['box'];
    if (page is! int || page < 1 || box is! List || box.length != 4) {
      return null;
    }
    if (box.any((v) => v is! num || !v.isFinite || v < 0 || v > 1000)) {
      return null;
    }
    final coords = box.cast<num>().map((v) => v.toDouble() / 1000).toList();
    if (coords[2] <= coords[0] || coords[3] <= coords[1]) return null;
    return ProblemLocation(
      page: page,
      top: coords[0],
      left: coords[1],
      bottom: coords[2],
      right: coords[3],
    );
  }
}

class CorrectedProblem {
  const CorrectedProblem({
    required this.question,
    required this.studentWork,
    required this.verdict,
    required this.explanation,
    required this.correctedSteps,
    this.location,
    this.marginNote,
  });
  final String question;
  final String studentWork;
  final String verdict;
  final String explanation;
  final List<String> correctedSteps;
  final ProblemLocation? location;
  final String? marginNote;
}
