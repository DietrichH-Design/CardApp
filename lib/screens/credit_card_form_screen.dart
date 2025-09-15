import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/credit_card_model.dart';
import '../services/credit_card_storage_service.dart';
import '../services/banned_countries_service.dart';

class CreditCardFormScreen extends StatefulWidget {
  const CreditCardFormScreen({super.key});

  @override
  State<CreditCardFormScreen> createState() => _CreditCardFormScreenState();
}

class _CreditCardFormScreenState extends State<CreditCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  
  String _selectedCountry = '';
  CardType _detectedCardType = CardType.unknown;
  bool _isLoading = false;
  String? _validationMessage;
  bool _isValidationError = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final cardNumber = _cardNumberController.text;
    final newCardType = CreditCardModel.inferCardType(cardNumber);
    
    if (newCardType != _detectedCardType) {
      setState(() {
        _detectedCardType = newCardType;
      });
    }
  }

  Future<void> _scanCreditCard() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showMessage('Camera permission is required to take photos', true);
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        // For now, show a dialog asking user to manually enter the card number
        // In a production app, you would use OCR to extract the card number
        _showCardScanDialog();
      }
    } catch (e) {
      _showMessage('Failed to access camera: ${e.toString()}', true);
    }
  }

  void _showCardScanDialog() {
    final TextEditingController scanController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Card Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter the card number from the photo:'),
            const SizedBox(height: 16),
            TextField(
              controller: scanController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                _CardNumberFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (scanController.text.isNotEmpty) {
                setState(() {
                  _cardNumberController.text = scanController.text;
                  _detectedCardType = CreditCardModel.inferCardType(scanController.text);
                });
                _showMessage('Card number entered successfully!', false);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Use Number'),
          ),
        ],
      ),
    );
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
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

  Future<void> _submitCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCountry.isEmpty) {
      _showMessage('Please select the issuing country', true);
      return;
    }

    setState(() {
      _isLoading = true;
      _validationMessage = null;
    });

    try {
      // Check if country is banned
      final countryValidation = await BannedCountriesService.instance.validateCountry(_selectedCountry);
      if (!countryValidation.isValid) {
        _showMessage(countryValidation.message, true);
        return;
      }

      // Create credit card model
      final creditCard = CreditCardModel(
        cardNumber: _cardNumberController.text.trim(),
        cardType: _detectedCardType,
        cvv: _cvvController.text.trim(),
        issuingCountry: _selectedCountry,
      );

      // Validate the card
      if (!creditCard.isValid) {
        _showMessage('Invalid credit card details. Please check the card number and CVV.', true);
        return;
      }

      // Save the card
      final saveResult = await CreditCardStorageService.instance.saveCard(creditCard);
      
      if (saveResult.success) {
        _showMessage(saveResult.message, false);
        _clearForm();
      } else {
        _showMessage(saveResult.message, true);
      }
    } catch (e) {
      _showMessage('An error occurred: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _cardNumberController.clear();
    _cvvController.clear();
    setState(() {
      _selectedCountry = '';
      _detectedCardType = CardType.unknown;
      _validationMessage = null;
    });
  }

  void _showMessage(String message, bool isError) {
    setState(() {
      _validationMessage = message;
      _isValidationError = isError;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a card number';
    }
    
    final cleanNumber = value.replaceAll(' ', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Card number must be between 13 and 19 digits';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) {
      return 'Card number must contain only digits';
    }
    
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    
    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'CVV must contain only digits';
    }
    
    return null;
  }

  Widget _buildCardTypeIcon() {
    IconData icon;
    Color color;
    
    switch (_detectedCardType) {
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
      default:
        icon = Icons.credit_card_outlined;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Credit Card'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Number Field
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Card Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _buildCardTypeIcon(),
                          const SizedBox(width: 8),
                          Text(
                            _detectedCardType.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          _CardNumberFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: '1234 5678 9012 3456',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _scanCreditCard,
                            tooltip: 'Scan Card',
                          ),
                        ),
                        validator: _validateCardNumber,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // CVV Field
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CVV',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          hintText: '123',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: _validateCVV,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Country Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issuing Country',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectCountry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCountry.isEmpty 
                                      ? 'Select issuing country'
                                      : _selectedCountry,
                                  style: TextStyle(
                                    color: _selectedCountry.isEmpty
                                        ? Theme.of(context).hintColor
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Validation Message
              if (_validationMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isValidationError 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isValidationError ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: _isValidationError ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitCard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Add Credit Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Clear Button
              OutlinedButton(
                onPressed: _clearForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Clear Form',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
