import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import './ocr_service.dart';

// Temporary OCR classes for testing
class OCRResult {
  final bool success;
  final String extractedText;
  final double confidence;
  final String? error;

  OCRResult({
    required this.success,
    required this.extractedText,
    required this.confidence,
    this.error,
  });
}

class PaymentTextAnalysis {
  final bool isPaymentRelated;
  final double confidence;
  final List<String> foundKeywords;
  final List<double> extractedAmounts;
  final List<String> extractedUpiIds;
  final String rawText;
  final List<String> validationErrors;
  final bool amountValid;
  final bool upiValid;
  final bool dateValid;
  final double evidenceScore;
  final String intelligentAnalysis;

  PaymentTextAnalysis({
    required this.isPaymentRelated,
    required this.confidence,
    required this.foundKeywords,
    required this.extractedAmounts,
    required this.extractedUpiIds,
    required this.rawText,
    this.validationErrors = const [],
    this.amountValid = false,
    this.upiValid = false,
    this.dateValid = false,
    this.evidenceScore = 0.0,
    this.intelligentAnalysis = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'isPaymentRelated': isPaymentRelated,
      'confidence': confidence,
      'foundKeywords': foundKeywords,
      'extractedAmounts': extractedAmounts,
      'extractedUpiIds': extractedUpiIds,
      'rawText': rawText,
      'validationErrors': validationErrors,
      'amountValid': amountValid,
      'upiValid': upiValid,
      'dateValid': dateValid,
      'evidenceScore': evidenceScore,
      'intelligentAnalysis': intelligentAnalysis,
    };
  }
}

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  Future<OCRResult> extractTextFromImage(Uint8List imageBytes) async {
    try {
      const apiKey = 'K87899142388957';
      const apiUrl = 'https://api.ocr.space/parse/image';

      // Make actual OCR API call
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['apikey'] = apiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'false';
      request.fields['detectOrientation'] = 'false';
      request.fields['scale'] = 'true';
      request.fields['OCREngine'] = '2';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'payment_screenshot.png',
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('OCR service timeout after 30 seconds');
        },
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['ParsedResults'] != null &&
            jsonResponse['ParsedResults'].isNotEmpty) {
          final extractedText =
              jsonResponse['ParsedResults'][0]['ParsedText'] ?? '';

          return OCRResult(
            success: true,
            extractedText: extractedText,
            confidence: 0.8,
            error: null,
          );
        } else {
          return OCRResult(
            success: false,
            extractedText: '',
            confidence: 0.0,
            error: 'No text could be extracted from the image.',
          );
        }
      } else {
        return OCRResult(
          success: false,
          extractedText: '',
          confidence: 0.0,
          error: 'OCR service returned error ${response.statusCode}.',
        );
      }
    } catch (e) {
      return OCRResult(
        success: false,
        extractedText: '',
        confidence: 0.0,
        error: 'OCR extraction failed: $e',
      );
    }
  }

  PaymentTextAnalysis analyzePaymentText(
    String extractedText, {
    required double expectedAmount,
    required String expectedUpiId,
  }) {
    print('\n=== STRICT PAYMENT VALIDATION ===');
    print('Expected Amount: ₹$expectedAmount');
    print('Expected UPI: $expectedUpiId');
    print(
      'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    print('Extracted Text: $extractedText');

    // Extract data from text
    final amounts = _extractAmounts(extractedText);
    final upiIds = _extractUpiIds(extractedText);
    final dates = _extractDates(extractedText);

    print('Found amounts: $amounts');
    print('Found UPI IDs: $upiIds');
    print('Found dates: $dates');

    // STRICT validation - all must match exactly
    bool amountValid = amounts.contains(expectedAmount);
    bool upiValid = upiIds.contains(expectedUpiId.toLowerCase());

    // Date must be today
    final today = DateTime.now();
    bool dateValid = dates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    // All conditions must be met
    bool isValid = amountValid && upiValid && dateValid;

    List<String> issues = [];
    if (!amountValid)
      issues.add(
        'Amount does not exactly match. Expected: ₹$expectedAmount, Found: $amounts',
      );
    if (!upiValid)
      issues.add(
        'UPI ID does not exactly match. Expected: $expectedUpiId, Found: $upiIds',
      );
    if (!dateValid)
      issues.add(
        'Date is not today. Expected: ${today.day}/${today.month}/${today.year}, Found: $dates',
      );

    print('VALIDATION RESULTS:');
    print('- Amount Match: ${amountValid ? "✅" : "❌"}');
    print('- UPI Match: ${upiValid ? "✅" : "❌"}');
    print('- Date Match: ${dateValid ? "✅" : "❌"}');
    print('FINAL RESULT: ${isValid ? "ACCEPTED" : "REJECTED"}');

    if (issues.isNotEmpty) {
      print('ISSUES: ${issues.join(", ")}');
    }

    return PaymentTextAnalysis(
      isPaymentRelated: isValid,
      confidence: isValid ? 1.0 : 0.0,
      foundKeywords: _findPaymentKeywords(extractedText),
      extractedAmounts: amounts,
      extractedUpiIds: upiIds,
      rawText: extractedText,
      validationErrors: issues,
      amountValid: amountValid,
      upiValid: upiValid,
      dateValid: dateValid,
      evidenceScore: isValid ? 100.0 : 0.0,
      intelligentAnalysis: isValid
          ? 'All criteria matched exactly'
          : 'Strict validation failed: ${issues.join(", ")}',
    );
  }

  List<double> _extractAmounts(String text) {
    final amounts = <double>[];
    final patterns = [
      RegExp(r'₹\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'amount\s*[:\-]?\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'\b(\d{2,6}(?:\.\d{2})?)\b'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0 && amount <= 100000) {
          amounts.add(amount);
        }
      }
    }

    return amounts.toSet().toList()..sort();
  }

  List<String> _extractUpiIds(String text) {
    final upiIds = <String>[];
    final pattern = RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)');

    for (final match in pattern.allMatches(text)) {
      final upiId = match.group(1);
      if (upiId != null && upiId.contains('@') && upiId.length > 5) {
        upiIds.add(upiId.toLowerCase());
      }
    }

    return upiIds.toSet().toList();
  }

  List<DateTime> _extractDates(String text) {
    final dates = <DateTime>[];

    // "22 Sept 2025" format
    final septPattern = RegExp(
      r'(\d{1,2})\s+sept?\s+(\d{4})',
      caseSensitive: false,
    );
    for (final match in septPattern.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (day != null &&
          year != null &&
          day >= 1 &&
          day <= 31 &&
          year >= 2020) {
        dates.add(DateTime(year, 9, day)); // September
      }
    }

    // DD/MM/YYYY format
    final standardPattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
    for (final match in standardPattern.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null &&
          month != null &&
          year != null &&
          day >= 1 &&
          day <= 31 &&
          month >= 1 &&
          month <= 12 &&
          year >= 2020) {
        dates.add(DateTime(year, month, day));
      }
    }

    return dates.toSet().toList();
  }

  List<String> _findPaymentKeywords(String text) {
    final keywords = <String>[];
    final paymentWords = [
      'payment',
      'paid',
      'transaction',
      'transfer',
      'sent',
      'received',
      'successful',
      'completed',
      'upi',
      'money',
      'amount',
      'rupees',
    ];

    final lowerText = text.toLowerCase();
    for (final word in paymentWords) {
      if (lowerText.contains(word)) {
        keywords.add(word);
      }
    }

    return keywords;
  }
}

/// Service for OCR-based payment verification from screenshots
class PaymentVerificationService {
  static final PaymentVerificationService _instance =
      PaymentVerificationService._internal();
  factory PaymentVerificationService() => _instance;
  PaymentVerificationService._internal();

  final OCRService _ocrService = OCRService();

  /// Verify payment screenshot using OCR with STRICT validation
  Future<PaymentVerificationResult> verifyPaymentScreenshot({
    required Uint8List imageBytes,
    required double expectedAmount,
    required String expectedUpiId,
    required String contributorName,
  }) async {
    if (kIsWeb) {
      // For web, use OCR-based verification
      return await _verifyPaymentForWeb(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
      );
    } else {
      // For mobile, use the same web approach for consistency
      return await _verifyPaymentForWeb(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
      );
    }
  }

  /// Web-compatible verification using OCR and strict validation
  Future<PaymentVerificationResult> _verifyPaymentForWeb({
    required Uint8List imageBytes,
    required double expectedAmount,
    required String expectedUpiId,
    required String contributorName,
  }) async {
    try {
      return await _performOCRVerification(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
      );
    } catch (e) {
      print('Web verification error: $e');
      return PaymentVerificationResult(
        isValid: false,
        confidence: 0.0,
        errors: <String>['Unable to verify payment. Please try again.'],
        extractedAmount: null,
        extractedUpiId: null,
        extractedDate: null,
        verificationMethod: 'Error handling',
      );
    }
  }

  /// Perform OCR-based verification of payment screenshot with STRICT validation
  Future<PaymentVerificationResult> _performOCRVerification({
    required Uint8List imageBytes,
    required double expectedAmount,
    required String expectedUpiId,
    required String contributorName,
  }) async {
    try {
      // Extract text from image using OCR
      final ocrResult = await _ocrService.extractTextFromImage(imageBytes);
      print('OCR Result: ${ocrResult.extractedText}');

      if (!ocrResult.success) {
        return PaymentVerificationResult(
          isValid: false,
          confidence: 0.0,
          errors: <String>[
            'Unable to read the screenshot. Please upload a clearer image.',
          ],
          extractedAmount: null,
          extractedUpiId: null,
          extractedDate: null,
          verificationMethod: 'OCR-based verification',
        );
      }

      // Analyze extracted text for payment information with STRICT validation
      final paymentAnalysis = _ocrService.analyzePaymentText(
        ocrResult.extractedText,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
      );
      print('Payment Analysis: ${paymentAnalysis.toJson()}');

      if (!paymentAnalysis.isPaymentRelated) {
        return PaymentVerificationResult(
          isValid: false,
          confidence: 0.0,
          errors: List<String>.from(paymentAnalysis.validationErrors),
          extractedAmount:
              expectedAmount, // Show expected amount, not wrong extracted amount
          extractedUpiId:
              expectedUpiId, // Show expected UPI, not wrong extracted UPI
          extractedDate: DateTime.now(),
          verificationMethod: 'OCR-based verification',
        );
      }

      // If validation passes, create success result
      return PaymentVerificationResult(
        isValid: true,
        confidence: paymentAnalysis.confidence,
        errors: <String>[], // No errors if validation passed
        extractedAmount:
            expectedAmount, // Show expected amount since validation passed
        extractedUpiId:
            expectedUpiId, // Show expected UPI since validation passed
        extractedDate: DateTime.now(),
        verificationMethod: 'OCR-based verification',
      );
    } catch (e) {
      print('OCR verification error: $e');
      return PaymentVerificationResult(
        isValid: false,
        confidence: 0.0,
        errors: <String>['Unable to verify payment. Please try again.'],
        extractedAmount: null,
        extractedUpiId: null,
        extractedDate: null,
        verificationMethod: 'OCR-based verification',
      );
    }
  }
}

/// Result of payment verification
class PaymentVerificationResult {
  final bool isValid;
  final double confidence;
  final List<String> errors;
  final double? extractedAmount;
  final String? extractedUpiId;
  final DateTime? extractedDate;
  final String? verificationMethod;

  PaymentVerificationResult({
    required this.isValid,
    required this.confidence,
    required this.errors,
    this.extractedAmount,
    this.extractedUpiId,
    this.extractedDate,
    this.verificationMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'confidence': confidence,
      'errors': errors,
      'extractedAmount': extractedAmount,
      'extractedUpiId': extractedUpiId,
      'extractedDate': extractedDate?.toIso8601String(),
      'verificationMethod': verificationMethod,
    };
  }
}
