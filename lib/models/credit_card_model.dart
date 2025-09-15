import 'package:credit_card_validator/credit_card_validator.dart';

enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown
}

class CreditCardModel {
  final String cardNumber;
  final CardType cardType;
  final String cvv;
  final String issuingCountry;
  final DateTime createdAt;

  CreditCardModel({
    required this.cardNumber,
    required this.cardType,
    required this.cvv,
    required this.issuingCountry,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a unique identifier for duplicate detection
  String get uniqueId => cardNumber.replaceAll(' ', '');

  // Validate the credit card
  bool get isValid {
    final validator = CreditCardValidator();
    final result = validator.validateCCNum(cardNumber.replaceAll(' ', ''));
    return result.isValid && cvv.length >= 3 && cvv.length <= 4;
  }

  // Infer card type from card number
  static CardType inferCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    
    if (cleanNumber.isEmpty) return CardType.unknown;
    
    // Visa: starts with 4
    if (cleanNumber.startsWith('4')) {
      return CardType.visa;
    }
    
    // Mastercard: starts with 5 or 2221-2720
    if (cleanNumber.startsWith('5') || 
        (cleanNumber.length >= 4 && 
         int.tryParse(cleanNumber.substring(0, 4)) != null &&
         int.parse(cleanNumber.substring(0, 4)) >= 2221 && 
         int.parse(cleanNumber.substring(0, 4)) <= 2720)) {
      return CardType.mastercard;
    }
    
    // American Express: starts with 34 or 37
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return CardType.americanExpress;
    }
    
    // Discover: starts with 6011, 622126-622925, 644-649, or 65
    if (cleanNumber.startsWith('6011') || 
        cleanNumber.startsWith('65') ||
        (cleanNumber.length >= 6 && 
         cleanNumber.substring(0, 6).compareTo('622126') >= 0 &&
         cleanNumber.substring(0, 6).compareTo('622925') <= 0) ||
        (cleanNumber.length >= 3 && 
         int.tryParse(cleanNumber.substring(0, 3)) != null &&
         int.parse(cleanNumber.substring(0, 3)) >= 644 && 
         int.parse(cleanNumber.substring(0, 3)) <= 649)) {
      return CardType.discover;
    }
    
    // Diners Club: starts with 300-305, 36, or 38
    if ((cleanNumber.length >= 3 && 
         int.tryParse(cleanNumber.substring(0, 3)) != null &&
         int.parse(cleanNumber.substring(0, 3)) >= 300 && 
         int.parse(cleanNumber.substring(0, 3)) <= 305) ||
        cleanNumber.startsWith('36') || 
        cleanNumber.startsWith('38')) {
      return CardType.dinersClub;
    }
    
    // JCB: starts with 3528-3589
    if (cleanNumber.length >= 4 && 
        int.tryParse(cleanNumber.substring(0, 4)) != null &&
        int.parse(cleanNumber.substring(0, 4)) >= 3528 && 
        int.parse(cleanNumber.substring(0, 4)) <= 3589) {
      return CardType.jcb;
    }
    
    // UnionPay: starts with 62
    if (cleanNumber.startsWith('62')) {
      return CardType.unionPay;
    }
    
    return CardType.unknown;
  }

  // Get card type display name
  String get cardTypeDisplayName {
    switch (cardType) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType.americanExpress:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.dinersClub:
        return 'Diners Club';
      case CardType.jcb:
        return 'JCB';
      case CardType.unionPay:
        return 'UnionPay';
      case CardType.unknown:
        return 'Unknown';
    }
  }

  // Get formatted card number (with spaces)
  String get formattedCardNumber {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length <= 4) return cleanNumber;
    
    String formatted = '';
    for (int i = 0; i < cleanNumber.length; i += 4) {
      if (i + 4 < cleanNumber.length) {
        formatted += '${cleanNumber.substring(i, i + 4)} ';
      } else {
        formatted += cleanNumber.substring(i);
      }
    }
    return formatted.trim();
  }

  // Get masked card number for display
  String get maskedCardNumber {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length < 4) return cleanNumber;
    
    final lastFour = cleanNumber.substring(cleanNumber.length - 4);
    final masked = '*' * (cleanNumber.length - 4);
    return '${masked.substring(0, masked.length ~/ 4 * 4).replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} ')}$lastFour';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'cardNumber': cardNumber,
      'cardType': cardType.toString(),
      'cvv': cvv,
      'issuingCountry': issuingCountry,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  static CreditCardModel fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      cardNumber: json['cardNumber'],
      cardType: CardType.values.firstWhere(
        (e) => e.toString() == json['cardType'],
        orElse: () => CardType.unknown,
      ),
      cvv: json['cvv'],
      issuingCountry: json['issuingCountry'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardModel && other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => uniqueId.hashCode;
}
