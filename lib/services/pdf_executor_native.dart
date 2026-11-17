import 'package:flutter/foundation.dart';
import 'pdf_composer.dart';

Future<Uint8List> executePdfBuild(PdfBuildJob job) =>
    compute(composeCorrectionPdf, job, debugLabel: 'compose-marked-pdf');
