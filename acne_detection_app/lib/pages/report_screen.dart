import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/report.dart';

class ReportModal extends StatelessWidget {
  final Report report;
  final Uint8List? imageBytes;

  const ReportModal({super.key, required this.report, this.imageBytes});

  PdfColor _getPdfColor(String label) {
    switch (label.toLowerCase()) {
      case 'blackhead': return PdfColors.blue;
      case 'papule': return PdfColors.orange;
      case 'pustule': return PdfColors.purple;
      case 'nodul': return PdfColors.cyan;
      default: return PdfColors.grey;
    }
  }

  Future<void> _downloadReportPDF(BuildContext context) async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }

    try {
      final pdf = pw.Document();
      final image = imageBytes != null ? pw.MemoryImage(imageBytes!) : null;
      
      const double pdfImgW = 400;
      const double pdfImgH = 300;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfContext) => [
            pw.Header(
              level: 0,
              child: pw.Text('LAPORAN ANALISIS KESEHATAN KULIT',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            if (image != null)
              pw.Center(
                child: pw.Container(
                  width: pdfImgW,
                  height: pdfImgH,
                  child: pw.Stack(
                    children: [
                      pw.Image(image, fit: pw.BoxFit.contain),
                      ...report.detections.map((d) {
                        return pw.Positioned(
                          left: d.box[0] * pdfImgW,
                          top: d.box[1] * pdfImgH,
                          child: pw.SizedBox(
                            width: d.box[2] * pdfImgW,
                            height: d.box[3] * pdfImgH,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: _getPdfColor(d.label), width: 1.5),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            pw.SizedBox(height: 24),
            pw.Text('Ringkasan Kondisi:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Bullet(text: 'Dominasi Kondisi: ${report.dominance}', style: const pw.TextStyle(fontSize: 14)),
            pw.Bullet(text: 'Tingkat Keparahan: ${report.severityLabel} (${(report.severityConfidence * 100).toStringAsFixed(1)}%)', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 24),
            pw.Text('Detail Temuan Deteksi:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FixedColumnWidth(50),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Jenis Masalah Kulit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Akurasi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...List.generate(report.detections.length, (index) {
                  final d = report.detections[index];
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${index + 1}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(d.label)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${(d.confidence * 100).toStringAsFixed(1)}%')),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final String path = Platform.isAndroid ? '/storage/emulated/0/Download' : (await getApplicationDocumentsDirectory()).path;
      final file = File('$path/Laporan_Jerawat_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil disimpan di folder Download')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hasil Analisis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 16),
                      if (imageBytes != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(imageBytes!, height: 240, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _infoRow('Dominasi Masalah', report.dominance),
                      const SizedBox(height: 12),
                      _infoRow('Tingkat Keparahan', '${report.severityLabel} (${(report.severityConfidence * 100).toStringAsFixed(1)}%)'),
                      const SizedBox(height: 32),
                      const Text('Detail Objek Terdeteksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      const SizedBox(height: 16),
                      ...report.detections.map((d) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(backgroundColor: Colors.pink.shade50, child: const Icon(Icons.face, color: Colors.pink, size: 20)),
                          title: Text(d.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text('${(d.confidence * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )).toList(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadReportPDF(context),
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          label: const Text('SIMPAN LAPORAN PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}