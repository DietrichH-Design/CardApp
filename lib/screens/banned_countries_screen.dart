import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../services/banned_countries_service.dart';

class BannedCountriesScreen extends StatefulWidget {
  const BannedCountriesScreen({super.key});

  @override
  State<BannedCountriesScreen> createState() => _BannedCountriesScreenState();
}

class _BannedCountriesScreenState extends State<BannedCountriesScreen> {
  List<String> _bannedCountries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBannedCountries();
  }

  Future<void> _loadBannedCountries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final countries = await BannedCountriesService.instance.getBannedCountries();
      setState(() {
        _bannedCountries = countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading banned countries: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) async {
        await BannedCountriesService.instance.addBannedCountry(country.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${country.name} added to banned countries'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBannedCountries();
      },
      countryListTheme: CountryListThemeData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        searchTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        inputDecoration: InputDecoration(
          hintText: 'Search country...',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  Future<void> _removeCountry(String country) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Country'),
        content: Text('Are you sure you want to remove $country from the banned countries list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BannedCountriesService.instance.removeBannedCountry(country);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$country removed from banned countries'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBannedCountries();
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text('Are you sure you want to reset the banned countries list to default values? This will overwrite your current list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BannedCountriesService.instance.resetToDefault();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banned countries list reset to default'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBannedCountries();
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to clear all banned countries? This will allow credit cards from all countries.'),
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
      await BannedCountriesService.instance.clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All banned countries cleared'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBannedCountries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banned Countries'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefault();
                  break;
                case 'clear':
                  _clearAll();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset to Default'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
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
          : Column(
              children: [
                // Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Banned Countries Configuration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Credit cards from these countries will be rejected during validation. You can add or remove countries from this list.',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_bannedCountries.length} countries banned',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Countries List
                Expanded(
                  child: _bannedCountries.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No banned countries',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'All countries are currently allowed',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _bannedCountries.length,
                          itemBuilder: (context, index) {
                            final country = _bannedCountries[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.block,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  country,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeCountry(country),
                                  tooltip: 'Remove from banned list',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCountry,
        tooltip: 'Add Banned Country',
        child: const Icon(Icons.add),
      ),
    );
  }
}
