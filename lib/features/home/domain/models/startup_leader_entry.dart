import 'package:flutter/material.dart';

class StartupLeaderEntry {
  final int rank;
  final String symbol;
  final String name;
  final String sector;
  final double marketCapCr; // ₹ Crore
  final double changePercent; // today's % change
  final Color color;

  const StartupLeaderEntry({
    required this.rank,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.marketCapCr,
    required this.changePercent,
    required this.color,
  });

  String get formattedMarketCap {
    if (marketCapCr >= 100000) {
      return '₹${(marketCapCr / 100000).toStringAsFixed(1)}L Cr';
    }
    if (marketCapCr >= 1000) {
      return '₹${(marketCapCr / 1000).toStringAsFixed(1)}K Cr';
    }
    return '₹${marketCapCr.toStringAsFixed(0)} Cr';
  }

  String get formattedChange {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  bool get isPositive => changePercent >= 0;
}
