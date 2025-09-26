import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import './ocr_service.dart';

/// Result of payment verification process
class PaymentVerificationResult {
  final bool isValid;
  final double confidence;
  final List<String> errors;
  final double? extractedAmount;
  final String? extractedUpiId;
  final String? extractedUtrNumber;
  final DateTime? extractedDate;
  final String verificationMethod;

  PaymentVerificationResult({
    required this.isValid,
    required this.confidence,
    required this.errors,
    required this.extractedAmount,
    required this.extractedUpiId,
    required this.extractedUtrNumber,
    required this.extractedDate,
    required this.verificationMethod,
  });
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
          developer.log(
            'UTR duplication check result: $isDuplicate for UTR: $utrNumber',
          );
          return isDuplicate;
        } else {
          developer.log('UTR check API error: ${data['error']}');
          return false; // Allow transaction on API error
        }
      } else {
        developer.log('UTR check HTTP error: ${response.statusCode}');
        return false; // Allow transaction on HTTP error
      }
    } catch (e) {
      developer.log('Error checking UTR duplication: $e');
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
      developer.log('Web verification error: $e');
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
      developer.log('OCR Result: ${ocrResult.extractedText}');

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
      developer.log('Payment Analysis: ${paymentAnalysis.toJson()}');

      // Check for UTR duplication if campaignId is provided and UTR is found
      if (campaignId != null &&
          paymentAnalysis.extractedUtrNumbers.isNotEmpty) {
        final extractedUtr = paymentAnalysis.extractedUtrNumbers.first;
        
        // CRITICAL: Normalize UTR before checking for duplicates
        // This ensures consistency with how UTRs are stored
        final normalizedUtr = extractedUtr.replaceAll(RegExp(r'\s+'), '');
        
        final isUtrDuplicate = await checkUtrDuplication(
          normalizedUtr, // Use normalized UTR for duplicate check
          campaignId,
        );

        if (isUtrDuplicate) {
          return PaymentVerificationResult(
            isValid: false,
            confidence: 0.0,
            errors: <String>[
              'This payment screenshot has already been used. UTR: $normalizedUtr already exists for this campaign.',
            ],
            extractedAmount: expectedAmount,
            extractedUpiId: expectedUpiId,
            extractedUtrNumber: normalizedUtr, // Return normalized UTR
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
              ? paymentAnalysis.extractedUtrNumbers.first.replaceAll(RegExp(r'\s+'), '')
              : null, // Normalize UTR for consistency
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
            ? paymentAnalysis.extractedUtrNumbers.first.replaceAll(RegExp(r'\s+'), '')
            : null, // Normalize UTR for consistency
        extractedDate: DateTime.now(),
        verificationMethod: 'OCR-based verification',
      );
    } catch (e) {
      developer.log('OCR verification error: $e');
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