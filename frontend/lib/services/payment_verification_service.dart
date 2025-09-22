import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'ocr_service.dart';

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
          extractedAmount: paymentAnalysis.extractedAmounts.isNotEmpty
              ? paymentAnalysis.extractedAmounts.first
              : null,
          extractedUpiId: paymentAnalysis.extractedUpiIds.isNotEmpty
              ? paymentAnalysis.extractedUpiIds.first
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
        extractedAmount: paymentAnalysis.extractedAmounts.isNotEmpty
            ? paymentAnalysis.extractedAmounts.first
            : expectedAmount,
        extractedUpiId: paymentAnalysis.extractedUpiIds.isNotEmpty
            ? paymentAnalysis.extractedUpiIds.first
            : expectedUpiId,
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
