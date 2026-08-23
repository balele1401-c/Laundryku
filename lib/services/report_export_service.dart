import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:archive/archive.dart';

import '../models/enums.dart';
import '../models/transaction_model.dart';

/// Service untuk mengekspor laporan keuangan & operasional LaundryKu ke format:
/// 1. PDF (.pdf) — didukung Printing.sharePdf cross-platform (Web & Mobile)
/// 2. Excel (.xlsx)
/// 3. Word (.docx)
class ReportExportService {
  /// Format rupiah sederhana untuk string teks
  static String _formatRupiah(double value) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(value);
  }

  /// Format tanggal sederhana
  static String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  static String _formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. EXPORT KE PDF
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generatePdfBytes({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document();

    // Gunakan font resmi via Printing agar mendukung karakter Unicode & Rupiah
    final baseFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.plusJakartaSansBold();

    // Kalkulasi metrik
    final totalOmzet = transactions.fold<double>(
        0, (sum, t) => sum + t.totalHarga);
    final totalTx = transactions.length;
    final rataRata = totalTx > 0 ? totalOmzet / totalTx : 0.0;

    final tunaiTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() != 'QRIS').toList();
    final qrisTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() == 'QRIS').toList();

    final omzetTunai = tunaiTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final omzetQris = qrisTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);

    final pctTunai = totalOmzet > 0 ? (omzetTunai / totalOmzet * 100) : 0.0;
    final pctQris = totalOmzet > 0 ? (omzetQris / totalOmzet * 100) : 0.0;

    // Daily grouping
    final Map<String, List<TransactionModel>> dailyMap = {};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.tanggalMasuk);
      dailyMap.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDays = dailyMap.keys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            // ── Header LaundryKu ─────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LAUNDRYKU',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Aplikasi Manajemen Operasional & Kasir Laundry',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),
                        child: pw.Text(
                          'LAPORAN KEUANGAN',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Periode: ${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Ringkasan Keuangan Box ────────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL OMZET',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.blue100,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatRupiah(totalOmzet),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL TRANSAKSI',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalTx Nota',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RATA-RATA NOTA',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatRupiah(rataRata),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Section Breakdown Metode Pembayaran ───────────────────────
            pw.Text(
              'BREAKDOWN METODE PEMBAYARAN',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Metode Pembayaran',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Jumlah Transaksi',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Total Omzet (Rp)',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Porsi (%)',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Tunai (Cash)',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${tunaiTxs.length} Transaksi',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_formatRupiah(omzetTunai),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${pctTunai.toStringAsFixed(1)}%',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('QRIS (Digital / QR)',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${qrisTxs.length} Transaksi',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_formatRupiah(omzetQris),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${pctQris.toStringAsFixed(1)}%',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TOTAL',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('$totalTx Transaksi',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_formatRupiah(totalOmzet),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('100.0%',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Section Breakdown Harian ──────────────────────────────────
            pw.Text(
              'BREAKDOWN HARIAN',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Tanggal',
                          style: pw.TextStyle(
                              fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Transaksi',
                          style: pw.TextStyle(
                              fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Tunai (Rp)',
                          style: pw.TextStyle(
                              fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('QRIS (Rp)',
                          style: pw.TextStyle(
                              fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Total Omzet (Rp)',
                          style: pw.TextStyle(
                              fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                ...sortedDays.map((dayKey) {
                  final dayTxs = dailyMap[dayKey]!;
                  final dTunai = dayTxs.where((t) => t.metodePembayaran.toUpperCase() != 'QRIS').fold<double>(0, (s, t) => s + t.totalHarga);
                  final dQris = dayTxs.where((t) => t.metodePembayaran.toUpperCase() == 'QRIS').fold<double>(0, (s, t) => s + t.totalHarga);
                  final dTotal = dayTxs.fold<double>(0, (s, t) => s + t.totalHarga);

                  final parsedDate = DateTime.tryParse(dayKey) ?? DateTime.now();

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatDateShort(parsedDate),
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${dayTxs.length}',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatRupiah(dTunai),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatRupiah(dQris),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatRupiah(dTotal),
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Section Rincian Transaksi ─────────────────────────────────
            pw.Text(
              'RINCIAN TRANSAKSI PERIODE INI ($totalTx Transaksi)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('No Nota',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Pelanggan',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Layanan',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Metode',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Bayar',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Status',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Total (Rp)',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                ...transactions.map((tx) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.nomorNota,
                            style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.customerNama,
                            style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.jenisLayanan,
                            style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.metodePembayaran,
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.statusPembayaran.label,
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(tx.status.label,
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(_formatRupiah(tx.totalHarga),
                            style: pw.TextStyle(
                                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Footer ───────────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dicetak otomatis oleh LaundryKu POS',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Tanggal Cetak: ${_formatDate(DateTime.now())} ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. EXPORT KE EXCEL (.xlsx)
  // ═══════════════════════════════════════════════════════════════════════════

  static Uint8List generateExcelBytes({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) {
    final excel = Excel.createExcel();

    // Rename default sheet to "Ringkasan"
    const sheetRingkasanName = 'Ringkasan';
    const sheetDetailName = 'Detail Transaksi';

    excel.rename('Sheet1', sheetRingkasanName);
    final sheetSummary = excel[sheetRingkasanName];
    final sheetDetail = excel[sheetDetailName];

    // Metrik Kalkulasi
    final totalOmzet = transactions.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final totalTx = transactions.length;
    final rataRata = totalTx > 0 ? totalOmzet / totalTx : 0.0;

    final tunaiTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() != 'QRIS').toList();
    final qrisTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() == 'QRIS').toList();

    final omzetTunai = tunaiTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final omzetQris = qrisTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);

    final pctTunai = totalOmzet > 0 ? (omzetTunai / totalOmzet * 100) : 0.0;
    final pctQris = totalOmzet > 0 ? (omzetQris / totalOmzet * 100) : 0.0;

    final kiloanTxs = transactions.where((t) => t.tipeLayanan == ServiceType.kiloan).length;
    final satuanTxs = transactions.where((t) => t.tipeLayanan == ServiceType.satuan).length;

    // ── SHEET 1: RINGKASAN ──────────────────────────────────────────────────
    sheetSummary.appendRow([TextCellValue('LAUNDRYKU - LAPORAN KEUANGAN & OPERASIONAL')]);
    sheetSummary.appendRow([TextCellValue('Periode: ${_formatDate(startDate)} s/d ${_formatDate(endDate)}')]);
    sheetSummary.appendRow([TextCellValue('Dicetak Pada: ${_formatDate(DateTime.now())} ${DateFormat('HH:mm').format(DateTime.now())}')]);
    sheetSummary.appendRow([TextCellValue('')]);

    // Ringkasan Utama Table
    sheetSummary.appendRow([TextCellValue('1. RINGKASAN UTAMA')]);
    sheetSummary.appendRow([TextCellValue('Indikator'), TextCellValue('Nilai')]);
    sheetSummary.appendRow([TextCellValue('Total Omzet'), DoubleCellValue(totalOmzet)]);
    sheetSummary.appendRow([TextCellValue('Total Transaksi'), IntCellValue(totalTx)]);
    sheetSummary.appendRow([TextCellValue('Rata-rata Nota'), DoubleCellValue(rataRata)]);
    sheetSummary.appendRow([TextCellValue('Transaksi Layanan Kiloan'), IntCellValue(kiloanTxs)]);
    sheetSummary.appendRow([TextCellValue('Transaksi Layanan Satuan'), IntCellValue(satuanTxs)]);
    sheetSummary.appendRow([TextCellValue('')]);

    // Breakdown Metode Pembayaran Table
    sheetSummary.appendRow([TextCellValue('2. BREAKDOWN METODE PEMBAYARAN')]);
    sheetSummary.appendRow([
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Jumlah Transaksi'),
      TextCellValue('Total Omzet (Rp)'),
      TextCellValue('Porsi (%)'),
    ]);
    sheetSummary.appendRow([
      TextCellValue('Tunai (Cash)'),
      IntCellValue(tunaiTxs.length),
      DoubleCellValue(omzetTunai),
      TextCellValue('${pctTunai.toStringAsFixed(1)}%'),
    ]);
    sheetSummary.appendRow([
      TextCellValue('QRIS (Digital)'),
      IntCellValue(qrisTxs.length),
      DoubleCellValue(omzetQris),
      TextCellValue('${pctQris.toStringAsFixed(1)}%'),
    ]);
    sheetSummary.appendRow([
      TextCellValue('TOTAL'),
      IntCellValue(totalTx),
      DoubleCellValue(totalOmzet),
      TextCellValue('100.0%'),
    ]);
    sheetSummary.appendRow([TextCellValue('')]);

    // Breakdown Harian Table
    sheetSummary.appendRow([TextCellValue('3. BREAKDOWN HARIAN')]);
    sheetSummary.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Jumlah Transaksi'),
      TextCellValue('Omzet Tunai (Rp)'),
      TextCellValue('Omzet QRIS (Rp)'),
      TextCellValue('Total Omzet (Rp)'),
    ]);

    final Map<String, List<TransactionModel>> dailyMap = {};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.tanggalMasuk);
      dailyMap.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDays = dailyMap.keys.toList()..sort();

    for (final dayKey in sortedDays) {
      final dayTxs = dailyMap[dayKey]!;
      final dTunai = dayTxs.where((t) => t.metodePembayaran.toUpperCase() != 'QRIS').fold<double>(0, (s, t) => s + t.totalHarga);
      final dQris = dayTxs.where((t) => t.metodePembayaran.toUpperCase() == 'QRIS').fold<double>(0, (s, t) => s + t.totalHarga);
      final dTotal = dayTxs.fold<double>(0, (s, t) => s + t.totalHarga);

      sheetSummary.appendRow([
        TextCellValue(dayKey),
        IntCellValue(dayTxs.length),
        DoubleCellValue(dTunai),
        DoubleCellValue(dQris),
        DoubleCellValue(dTotal),
      ]);
    }

    // ── SHEET 2: DETAIL TRANSAKSI ───────────────────────────────────────────
    sheetDetail.appendRow([
      TextCellValue('No'),
      TextCellValue('Nomor Nota'),
      TextCellValue('Tanggal'),
      TextCellValue('Pelanggan'),
      TextCellValue('Layanan'),
      TextCellValue('Tipe'),
      TextCellValue('Kuantitas / Berat'),
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Status Bayar'),
      TextCellValue('Status Alur'),
      TextCellValue('Total Biaya (Rp)'),
      TextCellValue('Kasir'),
    ]);

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final qtyText = tx.tipeLayanan == ServiceType.kiloan ? '${tx.berat ?? 0} kg' : '${tx.qty ?? 0} pcs';
      sheetDetail.appendRow([
        IntCellValue(i + 1),
        TextCellValue(tx.nomorNota),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(tx.tanggalMasuk)),
        TextCellValue(tx.customerNama),
        TextCellValue(tx.jenisLayanan),
        TextCellValue(tx.tipeLayanan.label),
        TextCellValue(qtyText),
        TextCellValue(tx.metodePembayaran),
        TextCellValue(tx.statusPembayaran.label),
        TextCellValue(tx.status.label),
        DoubleCellValue(tx.totalHarga),
        TextCellValue(tx.createdBy.isNotEmpty ? tx.createdBy : 'Kasir'),
      ]);
    }

    final excelBytes = excel.encode();
    return Uint8List.fromList(excelBytes ?? []);
  }

  static Future<File?> generateExcelReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) async {
    final bytes = generateExcelBytes(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
    );
    if (!kIsWeb) {
      final outputDir = await getTemporaryDirectory();
      final dateFileStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${outputDir.path}/Laporan_LaundryKu_$dateFileStr.xlsx');
      await file.writeAsBytes(bytes);
      return file;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. EXPORT KE WORD (.docx)
  // ═══════════════════════════════════════════════════════════════════════════

  static Uint8List generateWordBytes({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) {
    final totalOmzet = transactions.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final totalTx = transactions.length;
    final rataRata = totalTx > 0 ? totalOmzet / totalTx : 0.0;
    final tunaiTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() != 'QRIS').toList();
    final qrisTxs = transactions.where((t) => t.metodePembayaran.toUpperCase() == 'QRIS').toList();
    final omzetTunai = tunaiTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final omzetQris = qrisTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final kiloanTxs = transactions.where((t) => t.tipeLayanan == ServiceType.kiloan).length;
    final satuanTxs = transactions.where((t) => t.tipeLayanan == ServiceType.satuan).length;

    final docXml = StringBuffer();
    docXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    docXml.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    docXml.write('<w:body>');
    docXml.write(_buildWordParagraph('LAUNDRYKU', isTitle: true, isBold: true));
    docXml.write(_buildWordParagraph('LAPORAN KEUANGAN & OPERASIONAL BISNIS LAUNDRY', isSubtitle: true, isBold: true));
    docXml.write(_buildWordParagraph('Periode: ${_formatDate(startDate)} - ${_formatDate(endDate)}'));
    docXml.write('<w:p/>');
    docXml.write(_buildWordHeading('1. Ringkasan Eksekutif'));
    docXml.write('<w:tbl>');
    docXml.write(_buildWordTableRow(['Indikator', 'Nilai'], isHeader: true));
    docXml.write(_buildWordTableRow(['Total Omzet', _formatRupiah(totalOmzet)]));
    docXml.write(_buildWordTableRow(['Total Transaksi', '$totalTx']));
    docXml.write(_buildWordTableRow(['Rata-rata Nota', _formatRupiah(rataRata)]));
    docXml.write(_buildWordTableRow(['Kiloan', '$kiloanTxs']));
    docXml.write(_buildWordTableRow(['Satuan', '$satuanTxs']));
    docXml.write('</w:tbl>');
    docXml.write('<w:p/>');
    docXml.write(_buildWordHeading('2. Breakdown Metode Pembayaran'));
    docXml.write('<w:tbl>');
    docXml.write(_buildWordTableRow(['Metode', 'Jumlah', 'Total Omzet'], isHeader: true));
    docXml.write(_buildWordTableRow(['Tunai', '${tunaiTxs.length}', _formatRupiah(omzetTunai)]));
    docXml.write(_buildWordTableRow(['QRIS', '${qrisTxs.length}', _formatRupiah(omzetQris)]));
    docXml.write('</w:tbl>');
    docXml.write('</w:body></w:document>');

    final archive = Archive();
    const contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));
    const relsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));
    final docBytes = utf8.encode(docXml.toString());
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    final zipEncoder = ZipEncoder();
    final docxBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(docxBytes ?? []);
  }

  static Future<File?> generateWordReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) async {
    final bytes = generateWordBytes(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
    );
    if (!kIsWeb) {
      final outputDir = await getTemporaryDirectory();
      final dateFileStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${outputDir.path}/Laporan_LaundryKu_$dateFileStr.docx');
      await file.writeAsBytes(bytes);
      return file;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. UNIVERSAL SHARE / DOWNLOAD (WEB & MOBILE)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> sharePdfReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required String title,
  }) async {
    final pdfBytes = await generatePdfBytes(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
    );
    final dateFileStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Laporan_LaundryKu_$dateFileStr.pdf';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
      subject: title,
    );
  }

  static Future<void> shareExcelReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required String title,
  }) async {
    final bytes = generateExcelBytes(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
    );
    final dateFileStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Laporan_LaundryKu_$dateFileStr.xlsx';
    final xfile = XFile.fromData(
      bytes,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      name: filename,
    );
    await Share.shareXFiles([xfile], subject: title, text: '$title dari LaundryKu');
  }

  static Future<void> shareWordReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required String title,
  }) async {
    final bytes = generateWordBytes(
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
    );
    final dateFileStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Laporan_LaundryKu_$dateFileStr.docx';
    final xfile = XFile.fromData(
      bytes,
      mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      name: filename,
    );
    await Share.shareXFiles([xfile], subject: title, text: '$title dari LaundryKu');
  }

  static Future<void> shareExportedFile(File file, {required String title}) async {
    String mimeType = 'application/octet-stream';
    if (file.path.endsWith('.pdf')) {
      mimeType = 'application/pdf';
    } else if (file.path.endsWith('.xlsx')) {
      mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (file.path.endsWith('.docx')) {
      mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    final xfile = XFile(file.path, mimeType: mimeType);
    await Share.shareXFiles(
      [xfile],
      subject: title,
      text: '$title dari LaundryKu',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORD XML BUILDER HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _xmlEscape(String str) {
    return str
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _buildWordParagraph(
    String text, {
    bool isTitle = false,
    bool isSubtitle = false,
    bool isMuted = false,
    bool isBold = false,
    String? color,
  }) {
    final colorTag = color != null ? '<w:color w:val="$color"/>' : '';
    final boldTag = (isTitle || isSubtitle || isBold) ? '<w:b/>' : '';
    final sizeTag = isTitle
        ? '<w:sz w:val="36"/>'
        : (isSubtitle ? '<w:sz w:val="24"/>' : (isMuted ? '<w:sz w:val="18"/>' : '<w:sz w:val="22"/>'));
    final colorMuted = isMuted ? '<w:color w:val="64748B"/>' : '';

    return '<w:p><w:pPr><w:jc w:val="${isTitle || isSubtitle ? "left" : "left"}"/></w:pPr><w:r><w:rPr>$boldTag$sizeTag$colorTag$colorMuted</w:rPr><w:t>${_xmlEscape(text)}</w:t></w:r></w:p>';
  }

  static String _buildWordHeading(String title) {
    return '<w:p><w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="1E3A8A"/></w:rPr><w:t>${_xmlEscape(title)}</w:t></w:r></w:p>';
  }

  static String _buildWordTableRow(List<String> cells, {bool isHeader = false, bool isBold = false}) {
    final buffer = StringBuffer();
    buffer.write('<w:tr>');
    for (final cell in cells) {
      buffer.write('<w:tc>');
      buffer.write('<w:tcPr>');
      if (isHeader) {
        buffer.write('<w:shd w:val="clear" w:color="auto" w:fill="E2E8F0"/>');
      }
      buffer.write('<w:tcMar><w:top w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:left w:w="140" w:type="dxa"/><w:right w:w="140" w:type="dxa"/></w:tcMar>');
      buffer.write('</w:tcPr>');
      buffer.write('<w:p><w:r><w:rPr>');
      if (isHeader || isBold) {
        buffer.write('<w:b/>');
      }
      buffer.write('<w:sz w:val="${isHeader ? "20" : "19"}"/>');
      buffer.write('</w:rPr><w:t>${_xmlEscape(cell)}</w:t></w:r></w:p>');
      buffer.write('</w:tc>');
    }
    buffer.write('</w:tr>');
    return buffer.toString();
  }
}
