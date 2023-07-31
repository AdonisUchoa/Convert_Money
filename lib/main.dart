import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(ConvertMoneyApp());
}

class ConvertMoneyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Convert Money',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ConvertMoneyPage(),
    );
  }
}

class Currency {
  final String code;
  final String name;

  Currency(this.code, this.name);
}

class ConvertMoneyPage extends StatefulWidget {
  const ConvertMoneyPage({super.key});

  @override
  _ConvertMoneyPageState createState() => _ConvertMoneyPageState();
}

class _ConvertMoneyPageState extends State<ConvertMoneyPage> {
  final List<Currency> _currencies = [
    Currency("USD", "USD"),
    Currency("BRL", "BRL"),
    Currency("EUR", "EUR"),
    Currency("BTC", "BTC"),
  ];

  String _fromCurrency = "USD";
  String _toCurrency = "BRL";
  Map<String, dynamic> _exchangeRates = {};
  TextEditingController _amountController = TextEditingController();
  double _convertedValue = 0.0;

  @override
  void initState() {
    super.initState();
    _getExchangeRates();
  }

  Future<void> _getExchangeRates() async {
    final url =
        'https://economia.awesomeapi.com.br/json/last/$_fromCurrency-$_toCurrency';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _exchangeRates = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load exchange rates');
    }
  }

  List<Currency> _getFilteredCurrencies() {
    return _currencies
        .where((currency) => currency.code != _toCurrency)
        .toList();
  }

  List<Currency> _getFilteredToCurrencies() {
    return _currencies
        .where((currency) => currency.code != _fromCurrency)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert Money'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Conversion Result: ${_getConversionResult()}',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('From:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _fromCurrency,
                  items: _getFilteredCurrencies().map((Currency currency) {
                    return DropdownMenuItem<String>(
                      value: currency.code,
                      child: Text(currency.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _fromCurrency = newValue!;
                    });
                    _getExchangeRates();
                  },
                ),
                const SizedBox(width: 40),
                const Text('To:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _toCurrency,
                  items: _getFilteredToCurrencies().map((Currency currency) {
                    return DropdownMenuItem<String>(
                      value: currency.code,
                      child: Text(currency.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _toCurrency = newValue!;
                    });
                    _getExchangeRates();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _convertCurrency,
              child: Text('Convert'),
            ),
            const SizedBox(height: 20),
            Text(
              'Exchange Rate: ${_getExchangeRate()}',
            ),
          ],
        ),
      ),
    );
  }

  String _getConversionResult() {
    if (_exchangeRates.isEmpty) {
      return "Loading...";
    } else {
      final formattedValue = NumberFormat.currency(
        locale: 'en_US',
        symbol: '',
      ).format(_convertedValue);
      return formattedValue;
    }
  }

  String _getExchangeRate() {
    if (_exchangeRates.isNotEmpty) {
      final conversionValue = _getConversionValue(_fromCurrency, _toCurrency);
      if (conversionValue != null) {
        final formattedValue = NumberFormat.currency(
          locale: 'en_US',
          symbol: '',
        ).format(conversionValue);
        return formattedValue;
      }
    }
    return "N/A";
  }

  void _convertCurrency() {
    if (_exchangeRates.isNotEmpty) {
      final conversionValue = _getConversionValue(_fromCurrency, _toCurrency);
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      if (conversionValue != null) {
        setState(() {
          _convertedValue = amount * conversionValue;
        });
      }
    }
  }

  double? _getConversionValue(String fromCurrency, String toCurrency) {
    if (_exchangeRates.containsKey('$fromCurrency$toCurrency')) {
      final data = _exchangeRates['$fromCurrency$toCurrency'];
      if (data != null) {
        final bid = double.tryParse(data['bid']);
        if (bid != null) {
          return bid;
        }
      }
    }
    return null;
  }
}
