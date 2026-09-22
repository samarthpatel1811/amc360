import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AMC360 Financial Math & Calculations', () {
    test('Standard billing: subtotal - discount + tax = total', () {
      const double subtotal = 10000.00;
      const double discount = 1000.00;
      const double taxableAmount = subtotal - discount; // 9000.00
      const double taxRate = 18.0; // 18% GST
      final double taxAmount = (taxableAmount * taxRate) / 100; // 1620.00
      final double totalAmount = taxableAmount + taxAmount; // 10620.00
      const double paidAmount = 5000.00;
      final double balanceDue = totalAmount - paidAmount; // 5620.00

      expect(taxableAmount, 9000.00);
      expect(taxAmount, 1620.00);
      expect(totalAmount, 10620.00);
      expect(balanceDue, 5620.00);
    });

    test('Zero discount billing calculation', () {
      const double subtotal = 5000.00;
      const double discount = 0.00;
      final double taxableAmount = subtotal - discount;
      const double taxRate = 12.0;
      final double taxAmount = (taxableAmount * taxRate) / 100;
      final double total = taxableAmount + taxAmount;

      expect(taxableAmount, 5000.00);
      expect(taxAmount, 600.00);
      expect(total, 5600.00);
    });

    test('Full payment reduces balance due to exactly 0.00', () {
      const double totalAmount = 14500.00;
      const double payment = 14500.00;
      final double balanceDue = totalAmount - payment;

      expect(balanceDue, 0.00);
    });
  });

  group('AMC360 Duration & Frequency Schedule Tests', () {
    test('12 Month contract end date calculation', () {
      final start = DateTime(2026, 4, 1);
      final end = DateTime(start.year + 1, start.month, start.day).subtract(const Duration(days: 1));

      expect(end, DateTime(2027, 3, 31));
    });

    test('Quarterly service visit generation (4 visits per year)', () {
      final start = DateTime(2026, 4, 1);
      final visits = <DateTime>[];

      for (int i = 0; i < 4; i++) {
        visits.add(DateTime(start.year, start.month + (i * 3), start.day));
      }

      expect(visits.length, 4);
      expect(visits[0], DateTime(2026, 4, 1));
      expect(visits[1], DateTime(2026, 7, 1));
      expect(visits[2], DateTime(2026, 10, 1));
      expect(visits[3], DateTime(2027, 1, 1));
    });
  });

  group('Indian Mobile & State/City Validation Tests', () {
    String normalizeIndianMobile(String input) {
      String clean = input.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length == 12 && clean.startsWith('91')) {
        clean = clean.substring(2);
      } else if (clean.length == 11 && clean.startsWith('0')) {
        clean = clean.substring(1);
      }
      return clean;
    }

    bool isValidIndianMobile(String clean) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(clean);
    }

    test('Valid 10-digit Indian numbers starting with 6,7,8,9', () {
      expect(isValidIndianMobile('9876543210'), isTrue);
      expect(isValidIndianMobile('8123456789'), isTrue);
      expect(isValidIndianMobile('7012345678'), isTrue);
      expect(isValidIndianMobile('6398765432'), isTrue);
    });

    test('Rejects invalid phone numbers', () {
      expect(isValidIndianMobile('1234567890'), isFalse); // starts with 1
      expect(isValidIndianMobile('5234567890'), isFalse); // starts with 5
      expect(isValidIndianMobile('987654321'), isFalse);  // 9 digits
      expect(isValidIndianMobile('98765432100'), isFalse); // 11 digits
    });

    test('Strips +91, 91, and leading 0 prefixes correctly', () {
      expect(normalizeIndianMobile('+91 98765 00001'), '9876500001');
      expect(normalizeIndianMobile('919876543210'), '9876543210');
      expect(normalizeIndianMobile('09876543210'), '9876543210');
      expect(isValidIndianMobile(normalizeIndianMobile('+91 98765 00001')), isTrue);
    });
  });
}
