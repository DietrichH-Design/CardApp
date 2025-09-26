import 'package:flutter/foundation.dart';
import '../models/credit_card_model.dart';
import '../services/credit_card_storage_service.dart';

class CreditCardProvider extends ChangeNotifier {
  CreditCardProvider();

  bool _isLoading = false;
  List<CreditCardModel> _cards = [];
  StorageStats? _stats;

  bool get isLoading => _isLoading;
  List<CreditCardModel> get cards => List.unmodifiable(_cards);
  StorageStats? get stats => _stats;
  int get totalCards => _stats?.totalCards ?? _cards.length;

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      final cards = await CreditCardStorageService.instance.getStoredCards();
      final stats = await CreditCardStorageService.instance.getStorageStats();
      _cards = cards;
      _stats = stats;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCounts() async {
    final stats = await CreditCardStorageService.instance.getStorageStats();
    _stats = stats;
    notifyListeners();
  }

  Future<CardSaveResult> addCard(CreditCardModel card) async {
    _setLoading(true);
    try {
      final result = await CreditCardStorageService.instance.saveCard(card);
      if (result.success) {
        _cards = await CreditCardStorageService.instance.getStoredCards();
        _stats = await CreditCardStorageService.instance.getStorageStats();
        notifyListeners();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCard(String cardUniqueId) async {
    _setLoading(true);
    try {
      final success = await CreditCardStorageService.instance.removeCard(cardUniqueId);
      if (success) {
        _cards = await CreditCardStorageService.instance.getStoredCards();
        _stats = await CreditCardStorageService.instance.getStorageStats();
        notifyListeners();
      }
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAll() async {
    _setLoading(true);
    try {
      await CreditCardStorageService.instance.clearAllCards();
      _cards = [];
      _stats = await CreditCardStorageService.instance.getStorageStats();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
