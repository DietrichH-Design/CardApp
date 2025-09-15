import 'package:flutter/material.dart';
import '../models/credit_card_model.dart';
import '../services/credit_card_storage_service.dart';

class CreditCardListScreen extends StatefulWidget {
  const CreditCardListScreen({super.key});

  @override
  State<CreditCardListScreen> createState() => _CreditCardListScreenState();
}

class _CreditCardListScreenState extends State<CreditCardListScreen> {
  List<CreditCardModel> _cards = [];
  bool _isLoading = true;
  StorageStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await CreditCardStorageService.instance.getStoredCards();
      final stats = await CreditCardStorageService.instance.getStorageStats();
      
      setState(() {
        _cards = cards;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading cards: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCard(CreditCardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credit Card'),
        content: Text('Are you sure you want to delete the card ending in ${card.maskedCardNumber.substring(card.maskedCardNumber.length - 4)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CreditCardStorageService.instance.removeCard(card.uniqueId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credit card deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete credit card'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllCards() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cards'),
        content: const Text('Are you sure you want to delete all stored credit cards? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CreditCardStorageService.instance.clearAllCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All credit cards cleared'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCards();
    }
  }

  Widget _buildCardTypeIcon(CardType cardType) {
    IconData icon;
    Color color;
    
    switch (cardType) {
      case CardType.visa:
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case CardType.mastercard:
        icon = Icons.credit_card;
        color = Colors.red;
        break;
      case CardType.americanExpress:
        icon = Icons.credit_card;
        color = Colors.green;
        break;
      case CardType.discover:
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case CardType.dinersClub:
        icon = Icons.credit_card;
        color = Colors.purple;
        break;
      case CardType.jcb:
        icon = Icons.credit_card;
        color = Colors.indigo;
        break;
      case CardType.unionPay:
        icon = Icons.credit_card;
        color = Colors.teal;
        break;
      default:
        icon = Icons.credit_card_outlined;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 32);
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Cards',
                    _stats!.totalCards.toString(),
                    Icons.credit_card,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Card Types',
                    _stats!.cardTypeStats.length.toString(),
                    Icons.category,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Countries',
                    _stats!.countryStats.length.toString(),
                    Icons.public,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardItem(CreditCardModel card) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildCardTypeIcon(card.cardType),
        title: Text(
          card.maskedCardNumber,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              card.cardTypeDisplayName,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.issuingCountry,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Added: ${_formatDate(card.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteCard(card);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stored Credit Cards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_cards.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllCards();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No credit cards stored',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first credit card to get started',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  child: Column(
                    children: [
                      _buildStatsCard(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            return _buildCardItem(_cards[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
