import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/customer_model.dart';
import '../models/enums.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

/// Service untuk mencetak nota / struk transaksi LaundryKu dalam format PDF thermal receipt 80mm
/// menggunakan library `pdf` dan `printing`.
class ReceiptService {
  /// Format rupiah untuk teks struk
  static String _rupiah(double val) {
    return AppFormatters.rupiah(val);
  }

  /// Format tanggal struk
  static String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Generate dokumen PDF struk berukuran Roll 80mm
  static Future<Uint8List> generateReceiptPdf(
    TransactionModel tx, {
    CustomerModel? customer,
  }) async {
    final pdf = pw.Document();

    // Gunakan font resmi Google Fonts via printing agar mendukung Unicode tanpa warning
    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.plusJakartaSansBold();
    final monoFont = await PdfGoogleFonts.robotoMonoRegular();

    final isKiloan = tx.tipeLayanan == ServiceType.kiloan;
    final qtyStr = isKiloan ? '${tx.berat ?? 0} kg' : '${tx.qty ?? 0} pcs';
    final customerPhone = customer?.noHp ?? '';

    // Standard 80mm Roll Format (Lebar 80mm, tinggi dinamis)
    const roll80Format = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: roll80Format,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: [monoFont],
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // ── Header Toko ─────────────────────────────────────────────
              pw.Text(
                'LAUNDRYKU',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Bersih, Rapi, Wangi & Cepat',
                style: pw.TextStyle(font: regularFont, fontSize: 8),
              ),
              pw.Text(
                'Jl. Laundry Raya No. 88 | WA: 0812-3456-7890',
                style: pw.TextStyle(font: regularFont, fontSize: 7, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              _buildDashedLine(),
              pw.SizedBox(height: 4),

              // ── Info Nota ───────────────────────────────────────────────
              _buildReceiptRow('No. Nota', tx.nomorNota, isBoldValue: true, regularFont: regularFont, boldFont: boldFont),
              _buildReceiptRow('Tgl Masuk', _formatDateTime(tx.tanggalMasuk), regularFont: regularFont, boldFont: boldFont),
              _buildReceiptRow('Est. Selesai', _formatDateTime(tx.estimasiSelesai), regularFont: regularFont, boldFont: boldFont),
              _buildReceiptRow('Kasir', tx.createdBy.isNotEmpty ? tx.createdBy : 'Kasir', regularFont: regularFont, boldFont: boldFont),
              pw.SizedBox(height: 3),
              _buildDashedLine(),
              pw.SizedBox(height: 3),

              // ── Info Pelanggan ──────────────────────────────────────────
              _buildReceiptRow('Pelanggan', tx.customerNama, isBoldValue: true, regularFont: regularFont, boldFont: boldFont),
              if (customerPhone.isNotEmpty)
                _buildReceiptRow('No. HP / WA', customerPhone, regularFont: regularFont, boldFont: boldFont),
              pw.SizedBox(height: 4),
              _buildDashedLine(),
              pw.SizedBox(height: 4),

              // ── Detail Pesanan / Layanan ─────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  tx.jenisLayanan,
                  style: pw.TextStyle(font: boldFont, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '$qtyStr @ ${_rupiah(tx.hargaSatuan)}',
                    style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey800),
                  ),
                  pw.Text(
                    _rupiah(tx.totalHarga),
                    style: pw.TextStyle(font: boldFont, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              _buildDashedLine(),
              pw.SizedBox(height: 4),

              // ── Ringkasan Pembayaran ────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL BIAYA', style: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_rupiah(tx.totalHarga), style: pw.TextStyle(font: boldFont, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 3),
              _buildReceiptRow('Metode Bayar', tx.metodePembayaran, regularFont: regularFont, boldFont: boldFont),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status Bayar', style: pw.TextStyle(font: regularFont, fontSize: 8)),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: tx.isLunas ? PdfColors.green700 : PdfColors.red700, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Text(
                      tx.isLunas ? 'LUNAS' : 'BELUM BAYAR',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: tx.isLunas ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              _buildDashedLine(),
              pw.SizedBox(height: 6),

              // ── QR Code Nota ────────────────────────────────────────────
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: tx.nomorNota,
                width: 60,
                height: 60,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                tx.nomorNota,
                style: pw.TextStyle(font: monoFont, fontSize: 7, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),

              // ── Footer / Ketentuan ──────────────────────────────────────
              pw.Text(
                'SIMPAN NOTA INI SAAT PENGAMBILAN',
                style: pw.TextStyle(font: boldFont, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '1. Komplain maks. 1x24 jam setelah cucian diambil.\n2. Cucian tidak diambil >30 hari di luar tanggung jawab kami.',
                style: pw.TextStyle(font: regularFont, fontSize: 6, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Terima Kasih atas Kepercayaan Anda! 🙏',
                style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Cetak / Layout preview nota PDF thermal via Printing
  static Future<void> printReceipt(
    BuildContext context,
    TransactionModel tx, {
    CustomerModel? customer,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await generateReceiptPdf(tx, customer: customer);
      },
      name: 'Nota_${tx.nomorNota}.pdf',
    );
  }

  /// Bagikan / Share file PDF nota
  static Future<void> shareReceipt(
    TransactionModel tx, {
    CustomerModel? customer,
  }) async {
    final pdfBytes = await generateReceiptPdf(tx, customer: customer);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Nota_${tx.nomorNota}.pdf',
      subject: 'Nota LaundryKu - ${tx.nomorNota}',
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  static pw.Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBoldValue = false,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: regularFont, fontSize: 7.5, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isBoldValue ? boldFont : regularFont,
              fontSize: 7.5,
              fontWeight: isBoldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDashedLine() {
    return pw.Divider(
      borderStyle: pw.BorderStyle.dashed,
      thickness: 0.6,
      color: PdfColors.grey400,
    );
  }
}
