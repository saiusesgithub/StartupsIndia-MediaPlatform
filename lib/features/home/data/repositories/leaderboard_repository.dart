import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/startup_leader_entry.dart';

class LeaderboardRepository {
  static const _symbols = [
    'ZOMATO.NS',
    'SWIGGY.NS',
    'NYKAA.NS',
    'PAYTM.NS',
    'DELHIVERY.NS',
    'POLICYBZR.NS',
    'IXIGO.NS',
    'MAPMYINDIA.NS',
  ];

  static const _sectorMap = {
    'ZOMATO.NS': 'Food Delivery',
    'SWIGGY.NS': 'Food Delivery',
    'NYKAA.NS': 'Beauty & Fashion',
    'PAYTM.NS': 'Fintech',
    'DELHIVERY.NS': 'Logistics',
    'POLICYBZR.NS': 'Insurtech',
    'IXIGO.NS': 'Travel Tech',
    'MAPMYINDIA.NS': 'Mapping & GIS',
  };

  static const _colorMap = {
    'ZOMATO.NS': Color(0xFFE8341C),
    'SWIGGY.NS': Color(0xFFFC6011),
    'NYKAA.NS': Color(0xFFE91E63),
    'PAYTM.NS': Color(0xFF00BAF2),
    'DELHIVERY.NS': Color(0xFF6C5CE7),
    'POLICYBZR.NS': Color(0xFF0984E3),
    'IXIGO.NS': Color(0xFF00BA88),
    'MAPMYINDIA.NS': Color(0xFFF4B740),
  };

  Future<List<StartupLeaderEntry>> fetchLeaderboard() async {
    final symbolsParam = _symbols.join(',');
    final uri = Uri.parse(
      'https://query2.finance.yahoo.com/v7/finance/quote'
      '?symbols=$symbolsParam'
      '&fields=shortName,marketCap,regularMarketChangePercent',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results =
        (body['quoteResponse']?['result'] as List?) ?? [];

    if (results.isEmpty) throw Exception('No data returned');

    final parsed = results.map((r) {
      final symbol = r['symbol'] as String? ?? '';
      final marketCap = (r['marketCap'] as num?)?.toDouble() ?? 0;
      final change =
          (r['regularMarketChangePercent'] as num?)?.toDouble() ?? 0;
      final rawName = r['shortName'] as String? ?? symbol;
      return (
        symbol: symbol,
        name: _cleanName(rawName),
        sector: _sectorMap[symbol] ?? 'Tech',
        marketCapCr: marketCap / 1e7, // ₹ → ₹Cr (1 Cr = 10^7)
        changePercent: change,
        color: _colorMap[symbol] ?? const Color(0xFF6C5CE7),
      );
    }).toList();

    // Sort by market cap descending
    parsed.sort((a, b) => b.marketCapCr.compareTo(a.marketCapCr));

    return parsed.asMap().entries.map((e) {
      final v = e.value;
      return StartupLeaderEntry(
        rank: e.key + 1,
        symbol: v.symbol,
        name: v.name,
        sector: v.sector,
        marketCapCr: v.marketCapCr,
        changePercent: v.changePercent,
        color: v.color,
      );
    }).toList();
  }

  String _cleanName(String name) {
    return name
        .replaceAll(' Limited', '')
        .replaceAll(' Ltd.', '')
        .replaceAll(' Ltd', '')
        .replaceAll(' Inc.', '')
        .replaceAll(' Inc', '');
  }
}
