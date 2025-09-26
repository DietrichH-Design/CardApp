import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/credit_card_model.dart';

class CreditCardStorageService {
  static const String _creditCardsKey = 'stored_credit_cards';
  
  static CreditCardStorageService? _instance;
  static CreditCardStorageService get instance {
    _instance ??= CreditCardStorageService._();
    return _instance!;
  }

  CreditCardStorageService._();

  Future<List<CreditCardModel>> getStoredCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getString(_creditCardsKey);
    
    if (cardsJson != null) {
      final List<dynamic> decoded = json.decode(cardsJson);
      return decoded.map((cardData) => CreditCardModel.fromJson(cardData)).toList();
    }
    
    return [];
  }

  Future<CardSaveResult> saveCard(CreditCardModel card) async {
    final existingCards = await getStoredCards();

    final isDuplicate = existingCards.any((existingCard) => 
        existingCard.uniqueId == card.uniqueId);
    
    if (isDuplicate) {
      return CardSaveResult(
        success: false,
        isDuplicate: true,
        message: 'This credit card has already been captured',
        card: card,
      );
    }

    existingCards.add(card);

    final prefs = await SharedPreferences.getInstance();
    final cardsJson = json.encode(existingCards.map((c) => c.toJson()).toList());
    await prefs.setString(_creditCardsKey, cardsJson);
    
    return CardSaveResult(
      success: true,
      isDuplicate: false,
      message: 'Credit card saved successfully',
      card: card,
    );
  }


  Future<bool> removeCard(String cardUniqueId) async {
    final existingCards = await getStoredCards();
    final initialLength = existingCards.length;
    
    existingCards.removeWhere((card) => card.uniqueId == cardUniqueId);
    
    if (existingCards.length < initialLength) {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(existingCards.map((c) => c.toJson()).toList());
      await prefs.setString(_creditCardsKey, cardsJson);
      return true;
    }
    
    return false;
  }

  Future<void> clearAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_creditCardsKey);
  }

  Future<int> getCardsCount() async {
    final cards = await getStoredCards();
    return cards.length;
  }

  Future<bool> cardExists(String cardNumber) async {
    final cleanCardNumber = cardNumber.replaceAll(' ', '');
    final existingCards = await getStoredCards();
    return existingCards.any((card) => card.uniqueId == cleanCardNumber);
  }

  Future<List<CreditCardModel>> getCardsByType(CardType cardType) async {
    final allCards = await getStoredCards();
    return allCards.where((card) => card.cardType == cardType).toList();
  }

  Future<List<CreditCardModel>> getCardsByCountry(String country) async {
    final allCards = await getStoredCards();
    return allCards.where((card) => 
        card.issuingCountry.toLowerCase() == country.toLowerCase()).toList();
  }

  Future<List<CreditCardModel>> getRecentCards({int limit = 10}) async {
    final allCards = await getStoredCards();
    allCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allCards.take(limit).toList();
  }

  Future<String> exportCardsData() async {
    final cards = await getStoredCards();
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'cardsCount': cards.length,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
    return json.encode(exportData);
  }

  Future<StorageStats> getStorageStats() async {
    final cards = await getStoredCards();
    final cardTypeStats = <CardType, int>{};
    final countryStats = <String, int>{};
    
    for (final card in cards) {
      cardTypeStats[card.cardType] = (cardTypeStats[card.cardType] ?? 0) + 1;
      countryStats[card.issuingCountry] = (countryStats[card.issuingCountry] ?? 0) + 1;
    }
    
    return StorageStats(
      totalCards: cards.length,
      cardTypeStats: cardTypeStats,
      countryStats: countryStats,
      oldestCard: cards.isEmpty ? null : cards.reduce((a, b) => 
          a.createdAt.isBefore(b.createdAt) ? a : b),
      newestCard: cards.isEmpty ? null : cards.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b),
    );
  }
}

class CardSaveResult {
  final bool success;
  final bool isDuplicate;
  final String message;
  final CreditCardModel card;

  CardSaveResult({
    required this.success,
    required this.isDuplicate,
    required this.message,
    required this.card,
  });
}

class StorageStats {
  final int totalCards;
  final Map<CardType, int> cardTypeStats;
  final Map<String, int> countryStats;
  final CreditCardModel? oldestCard;
  final CreditCardModel? newestCard;

  StorageStats({
    required this.totalCards,
    required this.cardTypeStats,
    required this.countryStats,
    this.oldestCard,
    this.newestCard,
  });
}
