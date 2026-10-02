import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:je_fisc/core/errors/app_exception.dart';
import 'package:je_fisc/core/utils/app_logger.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';

/// The TrueType files the report is set in, as loaded from the assets.
typedef ReportFonts = ({ByteData regular, ByteData bold});

/// A work's visits as a PDF report — every visit's date, categories, notes
/// and pictures — saved where the user picks.
///
/// The document is built on a background isolate: embedding a visit's worth
/// of camera pictures takes long enough to freeze a frame or two.
class WorkReportDataSource {
  const WorkReportDataSource();

  /// Builds the report of [work] and asks the user where to save it. False
  /// when the dialog was dismissed.
  ///
  /// [visits] need their `pictures` and `categories` filled, as
  /// `fetchVisits` returns them; a picture whose file is gone is left out.
  Future<bool> exportVisits(WorkModel work, List<VisitModel> visits) async {
    final Uint8List bytes;
    try {
      // On this isolate: the asset bundle is not reachable from the other.
      final fonts = (
        regular: await rootBundle.load(_regularFont),
        bold: await rootBundle.load(_boldFont),
      );
      final generatedAt = DateTime.now();
      bytes = await Isolate.run(() => build(work, visits, generatedAt, fonts));
    } catch (e, st) {
      appLogger.e('[WorkReport] — $e', error: e, stackTrace: st);
      throw const StorageException(message: 'Não foi possível criar o PDF.');
    }
    final stamp = DateTime.now().format('yyyyMMdd_HHmm');
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Guardar relatório de visitas',
      fileName: 'visitas_${_fileSafe(work.clientName)}_$stamp.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    return saved != null;
  }

  /// Roboto, as `pubspec.yaml` bundles it: the pdf package's built-in
  /// Helvetica cannot draw much beyond Latin-1 — not a dash, not a curly
  /// quote — and the notes are whatever the user typed.
  static const _regularFont = 'assets/fonts/Roboto-Regular.ttf';
  static const _boldFont = 'assets/fonts/Roboto-Bold.ttf';

  /// [text] with anything a file name should not hold replaced by `_`.
  static String _fileSafe(String text) {
    final safe = text.withoutDiacritics
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return safe.isEmpty ? 'obra' : safe;
  }

  // ── Layout ───────────────────────────────────────────────────
  // Points — a PDF's unit, 1/72 inch — not the app's logical pixels, so
  // these are the document's own measures rather than AppConstants.

  static const _margin = 32.0;
  static const _gap = 8.0;
  static const _sectionGap = 16.0;
  static const _pictureHeight = 220.0;
  static const _picturesPerRow = 2;

  static const _muted = PdfColors.grey700;
  static const _rule = PdfColors.grey400;

  /// The report's bytes. What [exportVisits] runs on its isolate; public for
  /// the tests, which have no save dialog to get past.
  @visibleForTesting
  static Future<Uint8List> build(
    WorkModel work,
    List<VisitModel> visits,
    DateTime generatedAt,
    ReportFonts fonts,
  ) async {
    // Oldest first, so "Visita 1" is the first visit to the work.
    final ordered = [...visits]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    final sections = <pw.Widget>[];
    for (final (index, visit) in ordered.indexed) {
      sections.addAll(await _visit(visit, index + 1, ordered.length));
    }

    final doc = pw.Document(
      title: 'Relatório de visitas — ${work.clientName}',
      creator: 'JE Fisc',
    );
    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(fonts.regular),
          bold: pw.Font.ttf(fonts.bold),
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        footer: (context) => _footer(context, work),
        build: (context) => [
          _header(work, ordered.length, generatedAt),
          if (ordered.isEmpty)
            pw.Text(
              'Esta obra ainda não tem visitas.',
              style: const pw.TextStyle(color: _muted),
            )
          else
            ...sections,
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(WorkModel work, int visits, DateTime generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Relatório de visitas',
          style: const pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: _gap),
        pw.Text(
          work.clientName,
          style: const pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(work.address),
        pw.SizedBox(height: _gap),
        _field('Início', work.startDate.formattedDate),
        _field('Fim estimado', work.endDate?.formattedDate ?? '—'),
        _field('Visitas', '$visits'),
        _field('Gerado em', generatedAt.formattedDateTime),
        pw.SizedBox(height: _gap),
        pw.Divider(color: _rule),
        pw.SizedBox(height: _gap),
      ],
    );
  }

  /// One visit, as the separate pieces [pw.MultiPage] may break a page
  /// between — the pictures go one row at a time.
  static Future<List<pw.Widget>> _visit(
    VisitModel visit,
    int number,
    int total,
  ) async {
    final pictures = <pw.ImageProvider>[];
    for (final picture in visit.pictures) {
      final file = File(picture.picturePath);
      if (!await file.exists()) continue;
      try {
        pictures.add(pw.MemoryImage(await file.readAsBytes()));
      } catch (e) {
        // A format the PDF library cannot read: the report goes out
        // without that one rather than not at all.
        appLogger.w('[WorkReport] — skipped ${picture.picturePath}: $e');
      }
    }
    final notes = visit.notes;

    return [
      pw.Text(
        'Visita $number de $total — ${visit.date.formattedDate} '
        'às ${visit.date.formattedTime}',
        style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: _gap),
      _field(
        'Categorias',
        visit.categories.isEmpty
            ? 'Sem categorias'
            : visit.categories.map((c) => c.name).join(', '),
      ),
      if (notes != null) ...[
        pw.SizedBox(height: _gap / 2),
        pw.Text(
          'Notas',
          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(notes),
      ],
      pw.SizedBox(height: _gap),
      if (pictures.isEmpty)
        pw.Text('Sem fotografias.', style: const pw.TextStyle(color: _muted))
      else
        for (var i = 0; i < pictures.length; i += _picturesPerRow)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: _gap),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + _picturesPerRow; j++) ...[
                  if (j > i) pw.SizedBox(width: _gap),
                  pw.Expanded(
                    child: j < pictures.length
                        ? pw.SizedBox(
                            height: _pictureHeight,
                            child: pw.Image(
                              pictures[j],
                              fit: pw.BoxFit.contain,
                            ),
                          )
                        : pw.SizedBox(),
                  ),
                ],
              ],
            ),
          ),
      pw.SizedBox(height: _gap),
      pw.Divider(color: _rule),
      pw.SizedBox(height: _sectionGap),
    ];
  }

  static pw.Widget _field(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value),
      ],
    ),
  );

  static pw.Widget _footer(pw.Context context, WorkModel work) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        work.clientName,
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
      pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    ],
  );
}
