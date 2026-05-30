import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_error_reporter.dart';

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
    try {
      return await _fetchLive();
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to load leaderboard',
      );
      return _fallback();
    }
  }

  Future<List<StartupLeaderEntry>> _fetchLive() async {
    final symbolsParam = _symbols.join(',');
    final uri = Uri.parse(
      'https://query2.finance.yahoo.com/v7/finance/quote'
      '?symbols=$symbolsParam'
      '&fields=shortName,marketCap,regularMarketChangePercent',
    );

    final response = await http
        .get(
          uri,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['quoteResponse']?['result'] as List?) ?? [];

    if (results.isEmpty) throw Exception('No data returned');

    final parsed = results.map((r) {
      final symbol = r['symbol'] as String? ?? '';
      final marketCap = (r['marketCap'] as num?)?.toDouble() ?? 0;
      final change = (r['regularMarketChangePercent'] as num?)?.toDouble() ?? 0;
      final rawName = r['shortName'] as String? ?? symbol;
      return (
        symbol: symbol,
        name: _cleanName(rawName),
        sector: _sectorMap[symbol] ?? 'Tech',
        marketCapCr: marketCap / 1e7,
        changePercent: change,
        color: _colorMap[symbol] ?? const Color(0xFF6C5CE7),
      );
    }).toList();

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

  // Realistic placeholder data (May 2025 approximate figures).
  // Shown when the Yahoo Finance API is unreachable.
  static List<StartupLeaderEntry> _fallback() => const [
    StartupLeaderEntry(
      rank: 1,
      symbol: 'ZOMATO.NS',
      name: 'Zomato',
      sector: 'Food Delivery',
      marketCapCr: 196000,
      changePercent: 1.24,
      color: Color(0xFFE8341C),
    ),
    StartupLeaderEntry(
      rank: 2,
      symbol: 'NYKAA.NS',
      name: 'Nykaa',
      sector: 'Beauty & Fashion',
      marketCapCr: 54000,
      changePercent: -0.87,
      color: Color(0xFFE91E63),
    ),
    StartupLeaderEntry(
      rank: 3,
      symbol: 'POLICYBZR.NS',
      name: 'PolicyBazaar',
      sector: 'Insurtech',
      marketCapCr: 48500,
      changePercent: 0.53,
      color: Color(0xFF0984E3),
    ),
    StartupLeaderEntry(
      rank: 4,
      symbol: 'DELHIVERY.NS',
      name: 'Delhivery',
      sector: 'Logistics',
      marketCapCr: 21000,
      changePercent: -1.12,
      color: Color(0xFF6C5CE7),
    ),
    StartupLeaderEntry(
      rank: 5,
      symbol: 'PAYTM.NS',
      name: 'Paytm',
      sector: 'Fintech',
      marketCapCr: 19800,
      changePercent: 2.05,
      color: Color(0xFF00BAF2),
    ),
    StartupLeaderEntry(
      rank: 6,
      symbol: 'MAPMYINDIA.NS',
      name: 'MapmyIndia',
      sector: 'Mapping & GIS',
      marketCapCr: 15200,
      changePercent: 0.38,
      color: Color(0xFFF4B740),
    ),
    StartupLeaderEntry(
      rank: 7,
      symbol: 'IXIGO.NS',
      name: 'ixigo',
      sector: 'Travel Tech',
      marketCapCr: 12400,
      changePercent: -0.44,
      color: Color(0xFF00BA88),
    ),
    StartupLeaderEntry(
      rank: 8,
      symbol: 'SWIGGY.NS',
      name: 'Swiggy',
      sector: 'Food Delivery',
      marketCapCr: 10800,
      changePercent: 1.67,
      color: Color(0xFFFC6011),
    ),
  ];

  String _cleanName(String name) {
    return name
        .replaceAll(' Limited', '')
        .replaceAll(' Ltd.', '')
        .replaceAll(' Ltd', '')
        .replaceAll(' Inc.', '')
        .replaceAll(' Inc', '');
  }
}
