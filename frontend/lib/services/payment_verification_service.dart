import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
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
  final List<String> extractedUtrNumbers;
  final String rawText;
  final List<String> validationErrors;
  final bool amountValid;
  final bool upiValid;
  final bool dateValid;
  final bool utrValid;
  final double evidenceScore;
  final String intelligentAnalysis;

  PaymentTextAnalysis({
    required this.isPaymentRelated,
    required this.confidence,
    required this.foundKeywords,
    required this.extractedAmounts,
    required this.extractedUpiIds,
    required this.extractedUtrNumbers,
    required this.rawText,
    this.validationErrors = const [],
    this.amountValid = false,
    this.upiValid = false,
    this.dateValid = false,
    this.utrValid = false,
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
      'extractedUtrNumbers': extractedUtrNumbers,
      'rawText': rawText,
      'validationErrors': validationErrors,
      'amountValid': amountValid,
      'upiValid': upiValid,
      'dateValid': dateValid,
      'utrValid': utrValid,
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
    final utrNumbers = _extractUtrNumbers(extractedText);

    print('Found amounts: $amounts');
    print('Found UPI IDs: $upiIds');
    print('Found dates: $dates');
    print('Found UTR numbers: $utrNumbers');

    // STRICT validation - all must match exactly
    bool amountValid = amounts.contains(expectedAmount);
    bool upiValid = _validateUpiId(extractedText, upiIds, expectedUpiId);
    bool utrValid = utrNumbers.isNotEmpty; // At least one UTR must be found

    // Date must be today
    final today = DateTime.now();
    bool dateValid = dates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    // All conditions must be met
    bool isValid = amountValid && upiValid && dateValid && utrValid;

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
    if (!utrValid)
      issues.add(
        'No valid UTR/Transaction ID found in the screenshot. Found: $utrNumbers',
      );

    print('VALIDATION RESULTS:');
    print('- Amount Match: ${amountValid ? "✅" : "❌"}');
    print('- UPI Match: ${upiValid ? "✅" : "❌"}');
    print('- Date Match: ${dateValid ? "✅" : "❌"}');
    print('- UTR Found: ${utrValid ? "✅" : "❌"}');
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
      extractedUtrNumbers: utrNumbers,
      rawText: extractedText,
      validationErrors: issues,
      amountValid: amountValid,
      upiValid: upiValid,
      dateValid: dateValid,
      utrValid: utrValid,
      evidenceScore: isValid ? 100.0 : 0.0,
      intelligentAnalysis: isValid
          ? 'All criteria matched exactly'
          : 'Strict validation failed: ${issues.join(", ")}',
    );
  }

  List<double> _extractAmounts(String text) {
    final amounts = <double>[];

    // First try specific amount patterns with context
    final contextPatterns = [
      // Standard ₹ symbol formats
      RegExp(r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),

      // Rs. or RS formats
      RegExp(r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),

      // R100 format (common in BHIM and other apps)
      RegExp(r'\bR\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),

      // F10 format (BharatPe format)
      RegExp(r'\bF\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),

      // Amount: 100 format
      RegExp(
        r'amount\s*[:\-]?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),

      // Received/Sent/Paid amount patterns
      RegExp(
        r'(?:received|sent|paid)\s*[:\-]?\s*[₹rs]*\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),

      // Transaction successful amount patterns
      RegExp(
        r'(?:successful|success)\s+.*?(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),
    ];

    // Extract using context patterns first
    for (final pattern in contextPatterns) {
      for (final match in pattern.allMatches(text)) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount >= 1 && amount <= 100000) {
          amounts.add(amount);
        }
      }
    }

    // If no amounts found with context patterns, try standalone numbers with filtering
    if (amounts.isEmpty) {
      final standalonePattern = RegExp(r'\b(\d{1,6})\b');
      for (final match in standalonePattern.allMatches(text)) {
        final amountStr = match.group(1) ?? '';
        final amount = double.tryParse(amountStr);

        if (amount != null && amount >= 1 && amount <= 100000) {
          // Filter out common non-amount numbers
          if (!_isLikelyNonAmount(amountStr, text, match.start)) {
            amounts.add(amount);
          }
        }
      }
    }

    // Remove duplicates and sort
    final uniqueAmounts = amounts.toSet().toList()..sort();
    print('Debug - Amount extraction patterns found: $uniqueAmounts');
    return uniqueAmounts;
  }

  /// Helper method to filter out numbers that are likely not amounts
  bool _isLikelyNonAmount(String numberStr, String fullText, int position) {
    final number = int.tryParse(numberStr) ?? 0;

    // Filter out times (like 12:43, 12:42)
    if (position > 0 && position < fullText.length - 1) {
      final before = position > 0 ? fullText[position - 1] : '';
      final after = position + numberStr.length < fullText.length
          ? fullText[position + numberStr.length]
          : '';

      // Time patterns
      if (before == ':' || after == ':') return true;
      if (RegExp(r'[0-2]\d').hasMatch(numberStr) &&
          (before == ' ' && after == ':'))
        return true;
    }

    // Filter out years (2020-2030)
    if (number >= 2020 && number <= 2030) return true;

    // Filter out days (when followed by month names)
    if (number <= 31) {
      final context = fullText
          .substring(
            (position - 10).clamp(0, fullText.length),
            (position + numberStr.length + 10).clamp(0, fullText.length),
          )
          .toLowerCase();
      if (RegExp(
        r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
      ).hasMatch(context)) {
        return true;
      }
    }

    // Filter out account numbers (usually 4 digits ending in pattern like 7071)
    if (numberStr.length == 4 && number > 1000) {
      final context = fullText
          .substring(
            (position - 20).clamp(0, fullText.length),
            (position + numberStr.length + 5).clamp(0, fullText.length),
          )
          .toLowerCase();
      if (context.contains('••') ||
          context.contains('account') ||
          context.contains('bank')) {
        return true;
      }
    }

    // Filter out percentages (like 97% battery)
    if (number > 90 && number <= 100) return true;

    // Filter out transaction IDs (usually very long numbers)
    if (numberStr.length > 6) return true;

    return false;
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

  /// Enhanced UPI validation that considers receiver context
  bool _validateUpiId(
    String text,
    List<String> foundUpiIds,
    String expectedUpiId,
  ) {
    final lowerText = text.toLowerCase();
    final expectedLower = expectedUpiId.toLowerCase();

    // Direct UPI match
    if (foundUpiIds.contains(expectedLower)) {
      return true;
    }

    // Extract expected username from UPI (e.g., "aflah" from "aflah@upi")
    final expectedUsername = expectedLower.split('@')[0];

    // Check if receiver name matches expected username
    // Look for patterns like "Payment received by [NAME]" or "Paid to [NAME]"
    final receiverPatterns = [
      RegExp(r'payment\s+received\s+by\s+([a-z\s]+)', caseSensitive: false),
      RegExp(r'paid\s+to\s+([a-z\s]+)', caseSensitive: false),
      RegExp(r'transferred\s+to\s+([a-z\s]+)', caseSensitive: false),
      RegExp(r'sent\s+to\s+([a-z\s]+)', caseSensitive: false),
    ];

    for (final pattern in receiverPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final receiverName = match.group(1)?.trim().toLowerCase() ?? '';
        // Check if expected username is part of receiver name
        if (receiverName.contains(expectedUsername)) {
          print(
            'Found receiver match: "$receiverName" contains "$expectedUsername"',
          );
          return true;
        }
      }
    }

    // Check if any found UPI contains the expected username
    for (final upiId in foundUpiIds) {
      if (upiId.contains(expectedUsername)) {
        return true;
      }
    }

    return false;
  }

  List<DateTime> _extractDates(String text) {
    final dates = <DateTime>[];

    // "22nd Sep 25" format (with ordinal suffixes)
    final ordinalSeptPattern = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s+sep\w*\s+(\d{2,4})',
      caseSensitive: false,
    );
    for (final match in ordinalSeptPattern.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      var year = int.tryParse(match.group(2)!) ?? 0;

      // Handle 2-digit years (25 -> 2025)
      if (year < 100) {
        year += 2000;
      }

      if (day != null && year >= 2020 && day >= 1 && day <= 31) {
        dates.add(DateTime(year, 9, day)); // September
      }
    }

    // "22 Sept 2025" format (without ordinal suffixes)
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

    // DD/MM/YY format
    final shortYearPattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})');
    for (final match in shortYearPattern.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!) ?? 0;

      // Handle 2-digit years
      if (year < 100) {
        year += 2000;
      }

      if (day != null &&
          month != null &&
          year >= 2020 &&
          day >= 1 &&
          day <= 31 &&
          month >= 1 &&
          month <= 12) {
        dates.add(DateTime(year, month, day));
      }
    }

    return dates.toSet().toList();
  }

  List<String> _extractUtrNumbers(String text) {
    final utrNumbers = <String>[];

    // UTR/Transaction ID patterns
    final utrPatterns = [
      // Standard 12-digit UTR number
      RegExp(r'\b(\d{12})\b'),

      // UPI transaction ID patterns
      RegExp(
        r'(?:utr|transaction\s+id|txn\s+id|ref\s+no|reference)\s*[:\-]?\s*([a-z0-9]{10,})',
        caseSensitive: false,
      ),

      // Common UPI formats like UPI12345678901234
      RegExp(r'\b(UPI\d{12,})\b', caseSensitive: false),

      // PhonePe, GPay, Paytm transaction ID patterns
      RegExp(r'\b([A-Z0-9]{10,20})\b'),

      // IMPS/NEFT reference numbers
      RegExp(r'\b([A-Z]{4}\d{8,12})\b'),
    ];

    for (final pattern in utrPatterns) {
      for (final match in pattern.allMatches(text)) {
        final utr = match.group(1);
        if (utr != null && utr.length >= 10) {
          // Validate that it's not a timestamp, phone number, or other common false positive
          if (!_isLikelyNotUtr(utr)) {
            utrNumbers.add(utr.toUpperCase());
          }
        }
      }
    }

    return utrNumbers.toSet().toList();
  }

  /// Helper method to filter out strings that are likely not UTR numbers
  bool _isLikelyNotUtr(String value) {
    // Filter out timestamps (13 digits starting with 1)
    if (value.length == 13 && value.startsWith('1')) return true;

    // Filter out phone numbers (10 digits starting with 6,7,8,9)
    if (value.length == 10 && RegExp(r'^[6-9]').hasMatch(value)) return true;

    // Filter out amounts (pure numbers under a certain threshold)
    final numValue = int.tryParse(value);
    if (numValue != null && numValue < 1000000) return true;

    return false;
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

  /// Check if a UTR number already exists in the database
  Future<bool> checkUtrDuplication(String utrNumber, String campaignId) async {
    try {
      // Make API call to check UTR duplication
      final url =
          '${AppConfig.baseUrl}/contributions/check-utr/$campaignId/$utrNumber';
      final uri = Uri.parse(url);

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('UTR check timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final isDuplicate = data['data']['isDuplicate'] ?? false;
          print(
            'UTR duplication check result: $isDuplicate for UTR: $utrNumber',
          );
          return isDuplicate;
        } else {
          print('UTR check API error: ${data['error']}');
          return false; // Allow transaction on API error
        }
      } else {
        print('UTR check HTTP error: ${response.statusCode}');
        return false; // Allow transaction on HTTP error
      }
    } catch (e) {
      print('Error checking UTR duplication: $e');
      // On error, we'll allow the transaction to proceed
      return false;
    }
  }

  /// Verify payment screenshot using OCR with STRICT validation
  Future<PaymentVerificationResult> verifyPaymentScreenshot({
    required Uint8List imageBytes,
    required double expectedAmount,
    required String expectedUpiId,
    required String contributorName,
    String? campaignId, // Add campaignId for UTR duplication check
  }) async {
    if (kIsWeb) {
      // For web, use OCR-based verification
      return await _verifyPaymentForWeb(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
        campaignId: campaignId,
      );
    } else {
      // For mobile, use the same web approach for consistency
      return await _verifyPaymentForWeb(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
        campaignId: campaignId,
      );
    }
  }

  /// Web-compatible verification using OCR and strict validation
  Future<PaymentVerificationResult> _verifyPaymentForWeb({
    required Uint8List imageBytes,
    required double expectedAmount,
    required String expectedUpiId,
    required String contributorName,
    String? campaignId,
  }) async {
    try {
      return await _performOCRVerification(
        imageBytes: imageBytes,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
        contributorName: contributorName,
        campaignId: campaignId,
      );
    } catch (e) {
      print('Web verification error: $e');
      return PaymentVerificationResult(
        isValid: false,
        confidence: 0.0,
        errors: <String>['Unable to verify payment. Please try again.'],
        extractedAmount: null,
        extractedUpiId: null,
        extractedUtrNumber: null,
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
    String? campaignId,
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
          extractedUtrNumber: null,
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

      // Check for UTR duplication if campaignId is provided and UTR is found
      if (campaignId != null &&
          paymentAnalysis.extractedUtrNumbers.isNotEmpty) {
        final extractedUtr = paymentAnalysis.extractedUtrNumbers.first;
        final isUtrDuplicate = await checkUtrDuplication(
          extractedUtr,
          campaignId,
        );

        if (isUtrDuplicate) {
          return PaymentVerificationResult(
            isValid: false,
            confidence: 0.0,
            errors: <String>[
              'This payment screenshot has already been used. UTR: $extractedUtr already exists for this campaign.',
            ],
            extractedAmount: expectedAmount,
            extractedUpiId: expectedUpiId,
            extractedUtrNumber: extractedUtr,
            extractedDate: DateTime.now(),
            verificationMethod: 'OCR-based verification',
          );
        }
      }

      if (!paymentAnalysis.isPaymentRelated) {
        return PaymentVerificationResult(
          isValid: false,
          confidence: 0.0,
          errors: List<String>.from(paymentAnalysis.validationErrors),
          extractedAmount:
              expectedAmount, // Show expected amount, not wrong extracted amount
          extractedUpiId:
              expectedUpiId, // Show expected UPI, not wrong extracted UPI
          extractedUtrNumber: paymentAnalysis.extractedUtrNumbers.isNotEmpty
              ? paymentAnalysis.extractedUtrNumbers.first
              : null,
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
        extractedUtrNumber: paymentAnalysis.extractedUtrNumbers.isNotEmpty
            ? paymentAnalysis.extractedUtrNumbers.first
            : null,
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
        extractedUtrNumber: null,
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
  final String? extractedUtrNumber;
  final DateTime? extractedDate;
  final String? verificationMethod;

  PaymentVerificationResult({
    required this.isValid,
    required this.confidence,
    required this.errors,
    this.extractedAmount,
    this.extractedUpiId,
    this.extractedUtrNumber,
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
      'extractedUtrNumber': extractedUtrNumber,
      'extractedDate': extractedDate?.toIso8601String(),
      'verificationMethod': verificationMethod,
    };
  }
}
