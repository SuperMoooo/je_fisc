import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/features/work/data/datasources/work_report_datasource.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/visit_picture_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:path/path.dart' as p;

/// The PDF report builds — notes, categories, pictures (one of them gone),
/// a visit without any, and enough of them to need more than one page.
void main() {
  // A 1×1 PNG.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('je_fisc_report_test');
  });

  tearDown(() => dir.delete(recursive: true));

  test('builds a PDF of every visit', () async {
    final picture = File(p.join(dir.path, 'a.png'));
    await picture.writeAsBytes(png);

    final work = WorkModel(
      id: 1,
      clientName: 'Conceição Araújo',
      address: 'Rua de São João, Braga',
      startDate: DateTime(2026, 9),
    );
    final visits = [
      for (var i = 0; i < 6; i++)
        VisitModel(
          id: i,
          workId: 1,
          date: DateTime(2026, 9, 1 + i, 10, 30),
          notes: i.isEven
              ? 'Fissura na parede — “verificar”\nsegunda linha'
              : null,
          categories: [
            if (i != 3) const CategoryModel(id: 1, name: 'Fundações'),
          ],
          pictures: [
            if (i != 3)
              for (var j = 0; j < 3; j++)
                VisitPictureModel(id: j, visitId: i, picturePath: picture.path),
            VisitPictureModel(
              id: 99,
              visitId: i,
              picturePath: p.join(dir.path, 'gone.jpg'),
            ),
          ],
        ),
    ];

    Future<ByteData> font(String name) async => ByteData.sublistView(
      await File(p.join('assets', 'fonts', name)).readAsBytes(),
    );
    final bytes =
        await WorkReportDataSource.build(work, visits, DateTime(2026, 10, 2), (
          regular: await font('Roboto-Regular.ttf'),
          bold: await font('Roboto-Bold.ttf'),
        ));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
