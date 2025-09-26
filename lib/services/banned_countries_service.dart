import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BannedCountriesService {
  static const String _bannedCountriesKey = 'banned_countries';
  
  // Default banned countries list (can be modified by admins)
  static const List<String> _defaultBannedCountries = [
    'North Korea',
    'Iran',
    'Syria',
    'Cuba',
    'Sudan',
    'Venezuela',
    'Myanmar',
    'Belarus',
    'Afghanistan',
    'Somalia',
  ];

  static BannedCountriesService? _instance;
  static BannedCountriesService get instance {
    _instance ??= BannedCountriesService._();
    return _instance!;
  }

  BannedCountriesService._();

  Future<List<String>> getBannedCountries() async {
    final prefs = await SharedPreferences.getInstance();
    final bannedCountriesJson = prefs.getString(_bannedCountriesKey);
    
    if (bannedCountriesJson != null) {
      final List<dynamic> decoded = json.decode(bannedCountriesJson);
      return decoded.cast<String>();
    }

    return List.from(_defaultBannedCountries);
  }

  Future<void> setBannedCountries(List<String> countries) async {
    final prefs = await SharedPreferences.getInstance();
    final countriesJson = json.encode(countries);
    await prefs.setString(_bannedCountriesKey, countriesJson);
  }

  Future<bool> isCountryBanned(String country) async {
    final bannedCountries = await getBannedCountries();
    return bannedCountries.any((bannedCountry) => 
        bannedCountry.toLowerCase() == country.toLowerCase());
  }

  Future<void> addBannedCountry(String country) async {
    final currentList = await getBannedCountries();
    if (!currentList.any((c) => c.toLowerCase() == country.toLowerCase())) {
      currentList.add(country);
      await setBannedCountries(currentList);
    }
  }

  Future<void> removeBannedCountry(String country) async {
    final currentList = await getBannedCountries();
    currentList.removeWhere((c) => c.toLowerCase() == country.toLowerCase());
    await setBannedCountries(currentList);
  }

  Future<void> resetToDefault() async {
    await setBannedCountries(List.from(_defaultBannedCountries));
  }

  Future<void> clearAll() async {
    await setBannedCountries([]);
  }

  Future<CountryValidationResult> validateCountry(String country) async {
    final isBanned = await isCountryBanned(country);
    return CountryValidationResult(
      country: country,
      isValid: !isBanned,
      isBanned: isBanned,
      message: isBanned 
          ? 'Credit cards from $country are not accepted'
          : 'Country is valid',
    );
  }
}

class CountryValidationResult {
  final String country;
  final bool isValid;
  final bool isBanned;
  final String message;

  CountryValidationResult({
    required this.country,
    required this.isValid,
    required this.isBanned,
    required this.message,
  });
}
