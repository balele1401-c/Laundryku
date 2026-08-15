import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_keys.dart';
import '../utils/formatters.dart';

class WhatsAppSendResult {
  final bool isSuccess;
  final String? message;

  const WhatsAppSendResult({required this.isSuccess, this.message});
}

/// Service untuk mengirim notifikasi WhatsApp otomatis melalui Fonnte API.
class WhatsAppService {
  static const String _fonnteUrl = 'https://api.fonnte.com/send';

  /// Kirim pesan WhatsApp ke nomor HP tujuan.
  static Future<WhatsAppSendResult> sendMessage({
    required String noHp,
    required String pesan,
  }) async {
    if (ApiKeys.fonnteToken.trim().isEmpty) {
      debugPrint('⚠️ Token Fonnte belum diisi di lib/utils/api_keys.dart');
      return const WhatsAppSendResult(
        isSuccess: false,
        message: 'Token API Fonnte belum dikonfigurasi di api_keys.dart',
      );
    }

    final targetPhone = _normalizePhone(noHp);
    if (targetPhone.isEmpty) {
      return const WhatsAppSendResult(
        isSuccess: false,
        message: 'Nomor HP pelanggan tidak valid',
      );
    }

    try {
      debugPrint('📤 Mengirim pesan WA via Fonnte ke: $targetPhone');

      final response = await http
          .post(
            Uri.parse(_fonnteUrl),
            headers: {
              'Authorization': ApiKeys.fonnteToken.trim(),
            },
            body: {
              'target': targetPhone,
              'message': pesan,
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          debugPrint('✅ WhatsApp berhasil terkirim via Fonnte ke $targetPhone');
          return const WhatsAppSendResult(
            isSuccess: true,
            message: 'Pesan WhatsApp berhasil dikirim',
          );
        } else {
          final errMsg = data['reason'] ?? data['message'] ?? 'Gagal dari Fonnte';
          debugPrint('⚠️ Respon Fonnte status false: $errMsg');
          return WhatsAppSendResult(
            isSuccess: false,
            message: errMsg.toString(),
          );
        }
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
        return WhatsAppSendResult(
          isSuccess: false,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('❌ Exception saat kirim WA via Fonnte: $e');
      return WhatsAppSendResult(
        isSuccess: false,
        message: 'Koneksi error: ${e.toString()}',
      );
    }
  }

  /// Template default notifikasi status cucian siap diambil.
  static String generateReadyMessage({
    required String nama,
    required String nomorNota,
    required double totalHarga,
  }) {
    return 'Halo $nama, cucian Anda dengan nomor nota $nomorNota sudah SELESAI dan siap diambil ya! Total: ${AppFormatters.rupiah(totalHarga)}. Terima kasih sudah menggunakan LaundryKu 🙏';
  }

  /// Normalisasi nomor HP ke format Indonesia untuk Fonnte (e.g. 0812... / 62812...).
  static String _normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    return cleaned;
  }
}
