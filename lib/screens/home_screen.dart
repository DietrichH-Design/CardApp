import 'package:flutter/material.dart';
import '../services/credit_card_storage_service.dart';
import 'credit_card_form_screen.dart';
import 'credit_card_list_screen.dart';
import 'banned_countries_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalCards = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final count = await CreditCardStorageService.instance.getCardsCount();
      setState(() {
        _totalCards = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddCard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreditCardFormScreen(),
      ),
    ).then((_) => _loadStats()); // Refresh stats when returning
  }

  void _navigateToCardList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreditCardListScreen(),
      ),
    ).then((_) => _loadStats()); // Refresh stats when returning
  }

  void _navigateToBannedCountries() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BannedCountriesScreen(),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Text(
                'Credit Card Validator',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Stats Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Cards Stored',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _totalCards.toString(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Features Grid
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _buildFeatureCard(
                    title: 'Add Credit Card',
                    subtitle: 'Submit new card details with validation',
                    icon: Icons.add_card,
                    color: Colors.green,
                    onTap: _navigateToAddCard,
                  ),
                  _buildFeatureCard(
                    title: 'View Cards',
                    subtitle: 'Browse all stored credit cards',
                    icon: Icons.credit_card,
                    color: Colors.blue,
                    onTap: _navigateToCardList,
                    badge: _totalCards > 0 ? _totalCards.toString() : null,
                  ),
                  _buildFeatureCard(
                    title: 'Scan Card',
                    subtitle: 'Use camera to scan card details',
                    icon: Icons.camera_alt,
                    color: Colors.orange,
                    onTap: _navigateToAddCard, // Will open form with scan option
                  ),
                  _buildFeatureCard(
                    title: 'Banned Countries',
                    subtitle: 'Manage restricted countries list',
                    icon: Icons.block,
                    color: Colors.red,
                    onTap: _navigateToBannedCountries,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

}
