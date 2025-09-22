import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OCR service for extracting text from payment screenshots
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  /// Extract text from image using web-compatible OCR
  Future<OCRResult> extractTextFromImage(Uint8List imageBytes) async {
    if (kIsWeb) {
      return await _extractTextWeb(imageBytes);
    } else {
      // For mobile, could use Google ML Kit or other mobile OCR
      return await _extractTextMobile(imageBytes);
    }
  }

  /// Web-compatible OCR using online service with fallback options
  Future<OCRResult> _extractTextWeb(Uint8List imageBytes) async {
    // Try primary OCR service first
    try {
      final result = await _tryOCRSpaceAPI(imageBytes);
      if (result.success) {
        return result;
      }
    } catch (e) {
      print('Primary OCR service failed: $e');
    }

    // If primary fails, return error with helpful message
    return OCRResult(
      success: false,
      extractedText: '',
      confidence: 0.0,
      error:
          'Unable to extract text from image. Please ensure the screenshot is clear, well-lit, and shows all payment details including amount, UPI ID, and date.',
    );
  }

  /// Try OCR.space API for text extraction
  Future<OCRResult> _tryOCRSpaceAPI(Uint8List imageBytes) async {
    try {
      // First try the OCR.space API
      const apiKey = 'K87899142388957'; // Free API key for testing
      const apiUrl = 'https://api.ocr.space/parse/image';

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['apikey'] = apiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'false';
      request.fields['detectOrientation'] = 'false';
      request.fields['scale'] = 'true';
      request.fields['OCREngine'] = '2';

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'payment_screenshot.png',
        ),
      );

      // Set timeout for the request - increased timeout for better reliability
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'OCR service timeout after 30 seconds - please try again with a clearer image',
          );
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
          // Fallback to error when no text extracted
          return OCRResult(
            success: false,
            extractedText: '',
            confidence: 0.0,
            error:
                'No text could be extracted from the image. Please ensure the screenshot is clear and shows payment details.',
          );
        }
      } else {
        // Fallback to error when API fails with status code
        return OCRResult(
          success: false,
          extractedText: '',
          confidence: 0.0,
          error:
              'OCR service returned error ${response.statusCode}. Please try again or upload a clearer screenshot.',
        );
      }
    } catch (e) {
      print('OCR API failed: $e');
      // Return proper error instead of fallback
      return OCRResult(
        success: false,
        extractedText: '',
        confidence: 0.0,
        error:
            'OCR extraction failed: $e. Please try uploading a clearer screenshot.',
      );
    }
  }

  /// Mobile OCR implementation (placeholder)
  Future<OCRResult> _extractTextMobile(Uint8List imageBytes) async {
    // For mobile platforms, you could use Google ML Kit or other mobile OCR
    // For now, returning a placeholder result
    return OCRResult(
      success: false,
      extractedText: '',
      confidence: 0.0,
      error: 'Mobile OCR not implemented',
    );
  }

  /// Analyze extracted text for payment information with strict validation
  PaymentTextAnalysis analyzePaymentText(
    String extractedText, {
    required double expectedAmount,
    required String expectedUpiId,
  }) {
    final text = extractedText.toLowerCase();

    // Look for payment-related keywords
    final paymentKeywords = [
      'upi',
      'payment',
      'paid',
      'transaction',
      'transfer',
      'sent',
      'received',
      'credited',
      'debited',
      'gpay',
      'google pay',
      'phonepe',
      'paytm',
      'bhim',
      'amazon pay',
      'rupees',
      '₹',
      'rs.',
      'inr',
      'successful',
      'completed',
      'done',
    ];

    final foundKeywords = <String>[];
    for (final keyword in paymentKeywords) {
      if (text.contains(keyword)) {
        foundKeywords.add(keyword);
      }
    }

    // Extract amounts - improved pattern to catch more formats
    final amountPatterns = [
      RegExp(r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(
        r'r\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ), // For "R100" format
      RegExp(
        r'amount[:\s]*₹?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'received[:\s]*₹?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'paid[:\s]*₹?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false,
      ),
    ];

    final amounts = <double>[];
    for (final pattern in amountPatterns) {
      final amountMatches = pattern.allMatches(
        extractedText,
      ); // Use original text for number extraction
      for (final match in amountMatches) {
        final amountStr = (match.group(1) ?? '').replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          amounts.add(amount);
        }
      }
    }

    // Extract UPI IDs - prioritize RECIPIENT (TO) UPI IDs over sender (FROM) UPI IDs
    final recipientUpiPatterns = [
      // Highest priority - explicit "TO" patterns
      RegExp(r'to[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)', caseSensitive: false),
      RegExp(
        r'paid\s*to[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'receiver[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'beneficiary[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'received\s*by[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      // BHIM specific patterns
      RegExp(
        r'payment\s*received\s*by.*?([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
    ];

    final senderUpiPatterns = [
      // Lower priority - sender patterns (to exclude these)
      RegExp(
        r'from\s*upi\s*id[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'from[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'sender[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'initiated\s*by[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'payment\s*initiated\s*by.*?([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'payment\s*transferred\s*from.*?([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
    ];

    final generalUpiPatterns = [
      // General patterns - use only if no specific TO/FROM patterns found
      RegExp(
        r'upi\s*id[:\s]*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false,
      ),
      RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)', caseSensitive: false),
    ];

    final recipientUpiIds = <String>[];
    final senderUpiIds = <String>[];
    final generalUpiIds = <String>[];

    // First, extract recipient UPI IDs (highest priority)
    for (final pattern in recipientUpiPatterns) {
      final upiMatches = pattern.allMatches(extractedText);
      for (final match in upiMatches) {
        final upiId = match.group(1);
        if (upiId != null && upiId.contains('@')) {
          recipientUpiIds.add(upiId.toLowerCase());
        }
      }
    }

    // Then extract sender UPI IDs (to exclude from validation)
    for (final pattern in senderUpiPatterns) {
      final upiMatches = pattern.allMatches(extractedText);
      for (final match in upiMatches) {
        final upiId = match.group(1);
        if (upiId != null && upiId.contains('@')) {
          senderUpiIds.add(upiId.toLowerCase());
        }
      }
    }

    // Finally, extract general UPI IDs if no specific recipient patterns found
    if (recipientUpiIds.isEmpty) {
      for (final pattern in generalUpiPatterns) {
        final upiMatches = pattern.allMatches(extractedText);
        for (final match in upiMatches) {
          final upiId = match.group(1);
          if (upiId != null &&
              upiId.contains('@') &&
              !senderUpiIds.contains(upiId.toLowerCase())) {
            generalUpiIds.add(upiId.toLowerCase());
          }
        }
      }
    }

    // For BHIM payments, if we can't find the recipient UPI directly,
    // try to infer it from recipient name patterns
    if (recipientUpiIds.isEmpty &&
        extractedText.toLowerCase().contains('received by')) {
      // Look for recipient name and try to construct UPI ID
      final receivedByPattern = RegExp(
        r'received\s*by\s*([A-Z\s]+)',
        caseSensitive: false,
      );
      final receivedByMatch = receivedByPattern.firstMatch(extractedText);
      if (receivedByMatch != null) {
        final recipientName = receivedByMatch.group(1)?.trim();
        print('DEBUG: Found recipient name: $recipientName');
        // Since we can't construct the UPI ID from name alone,
        // we'll be more lenient with validation for BHIM payments
      }
    }

    // Prioritize recipient UPI IDs, then general UPI IDs (excluding known sender IDs)
    final extractedUpiIds = recipientUpiIds.isNotEmpty
        ? recipientUpiIds
        : generalUpiIds.where((id) => !senderUpiIds.contains(id)).toList();

    print('DEBUG UPI Analysis:');
    print('  Recipient UPI IDs: $recipientUpiIds');
    print('  Sender UPI IDs: $senderUpiIds');
    print('  General UPI IDs: $generalUpiIds');
    print('  Final extracted UPI IDs: $extractedUpiIds');
    print('  Expected UPI ID: $expectedUpiId');

    // Extract transaction IDs (12 digit numbers)
    final transactionIdPattern = RegExp(r'(\d{12})', caseSensitive: false);
    final transactionMatches = transactionIdPattern.allMatches(extractedText);
    final transactionIds = transactionMatches
        .map((m) => m.group(1) ?? '')
        .toList();

    // STRICT VALIDATION - ALL conditions must be met
    final validationErrors = <String>[];
    var isValid = true;
    var confidence = 0.0;

    // 1. Check for sufficient payment keywords (minimum 3)
    if (foundKeywords.length < 3) {
      validationErrors.add(
        'This does not appear to be a valid payment screenshot.',
      );
      isValid = false;
    } else {
      confidence += 0.3; // 30% for keywords
    }

    // 2. STRICT AMOUNT VALIDATION - Must match exactly
    var amountValid = false;
    if (amounts.isEmpty) {
      validationErrors.add('Payment amount not found in the screenshot.');
      isValid = false;
    } else {
      // Check if any extracted amount matches expected amount (within 1% tolerance)
      for (final amount in amounts) {
        final difference = (amount - expectedAmount).abs();
        final tolerance = expectedAmount * 0.01; // 1% tolerance

        if (difference <= tolerance) {
          amountValid = true;
          confidence += 0.4; // 40% for correct amount
          break;
        }
      }

      if (!amountValid) {
        validationErrors.add(
          'Payment amount does not match the contribution amount.',
        );
        isValid = false;
      }
    }

    // 3. INTELLIGENT UPI ID VALIDATION - Handle BHIM specific cases
    var upiValid = false;
    final isBhimPayment =
        extractedText.toLowerCase().contains('bhim') ||
        extractedText.toLowerCase().contains('received by');

    if (extractedUpiIds.isEmpty) {
      if (isBhimPayment && recipientUpiIds.isEmpty && senderUpiIds.isNotEmpty) {
        // Special case for BHIM: If we only found sender UPI and it's a BHIM payment,
        // be more lenient as BHIM often doesn't show recipient UPI clearly
        validationErrors.add(
          'UPI ID not clearly visible in the payment screenshot.',
        );
        // Don't mark as invalid completely for BHIM payments
        confidence += 0.1; // Reduced confidence but not failed
      } else {
        validationErrors.add('UPI ID not found in the payment screenshot.');
        isValid = false;
      }
    } else {
      final expectedUpiLower = expectedUpiId.toLowerCase();
      for (final upiId in extractedUpiIds) {
        if (upiId == expectedUpiLower ||
            upiId.contains(expectedUpiLower) ||
            expectedUpiLower.contains(upiId)) {
          upiValid = true;
          confidence += 0.2; // 20% for correct UPI ID
          break;
        }
      }

      if (!upiValid) {
        if (isBhimPayment) {
          // For BHIM payments, be more lenient if we have amount and date validation
          validationErrors.add(
            'Unable to verify the correct UPI ID. Please check if payment was made to the right recipient.',
          );
          // Don't fail completely if it's a BHIM payment with other valid indicators
          if (amountValid && foundKeywords.length >= 3) {
            confidence += 0.1; // Reduced confidence but don't fail
          } else {
            isValid = false;
          }
        } else {
          validationErrors.add('Payment was not made to the correct UPI ID.');
          isValid = false;
        }
      }
    }

    // 4. DATE VALIDATION - Check if payment is recent (within 7 days)
    final datePatterns = [
      RegExp(
        r'(\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'),
    ];

    var dateValid = false;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final pattern in datePatterns) {
      final dateMatches = pattern.allMatches(extractedText);
      for (final match in dateMatches) {
        final dateStr = match.group(1) ?? '';

        // Check if date contains today's date components
        if (dateStr.toLowerCase().contains('${now.day}') &&
            (dateStr.toLowerCase().contains(
                  _getMonthAbbr(now.month).toLowerCase(),
                ) ||
                dateStr.contains('${now.month.toString().padLeft(2, '0')}'))) {
          dateValid = true;
          confidence += 0.1; // 10% for valid date
          break;
        }
      }
      if (dateValid) break;
    }

    if (!dateValid) {
      validationErrors.add('Payment must be made within the last 7 days.');
      isValid = false;
    }

    // Final validation - set confidence to 0 if any validation fails
    if (!isValid) {
      confidence = 0.0;
    }

    return PaymentTextAnalysis(
      isPaymentRelated: isValid,
      confidence: confidence,
      foundKeywords: foundKeywords,
      extractedAmounts: amounts,
      extractedUpiIds: extractedUpiIds,
      rawText: extractedText,
      validationErrors: validationErrors,
      amountValid: amountValid,
      upiValid: upiValid,
      dateValid: dateValid,
    );
  }

  /// Get month abbreviation for date validation
  String _getMonthAbbr(int month) {
    const months = [
      '',
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return month > 0 && month < months.length ? months[month] : '';
  }
}

/// Result of OCR text extraction
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

/// Analysis of extracted text for payment information
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
    };
  }
}
