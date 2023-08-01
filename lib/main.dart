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

  String _fromCurrency = "BTC";
  String _toCurrency = "BRL";
  Map<String, dynamic> _exchangeRates = {};
  double _amount = 1.0;
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

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    return _currencies.map((Currency currency) {
      return DropdownMenuItem<String>(
        value: currency.code,
        child: Text(currency.name),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convert Money'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _fromCurrency,
                      items: _buildDropdownMenuItems(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _fromCurrency = newValue!;
                        });
                        _getExchangeRates();
                      },
                    ),
                    Icon(Icons.arrow_forward),
                    DropdownButton<String>(
                      value: _toCurrency,
                      items: _buildDropdownMenuItems(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _toCurrency = newValue!;
                        });
                        _getExchangeRates();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Current Exchange Rate: ${_getExchangeRate()}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter Amount',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _amount = double.tryParse(value) ?? 0.0;
                      _convertedValue =
                          _getConversionValue(_fromCurrency, _toCurrency) ??
                              0.0;
                    });
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Converted Value: ${NumberFormat.currency(
                    locale: 'en_US',
                    symbol: '',
                  ).format(_convertedValue)}',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getExchangeRate() {
    if (_exchangeRates.isNotEmpty) {
      final conversionValue = _getConversionValue(_fromCurrency, _toCurrency);
      if (conversionValue != null) {
        return conversionValue.toString();
      }
    }
    return "N/A";
  }

  double? _getConversionValue(String fromCurrency, String toCurrency) {
    if (_exchangeRates.containsKey('$fromCurrency$toCurrency')) {
      final data = _exchangeRates['$fromCurrency$toCurrency'];
      if (data != null) {
        final bid = double.tryParse(data['bid']);
        if (bid != null) {
          return bid * _amount;
        }
      }
    }
    return null;
  }
}
