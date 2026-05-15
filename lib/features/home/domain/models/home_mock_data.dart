import 'package:flutter/material.dart';

class HomeFeaturedStory {
  final String badge;
  final String headline;
  final String highlightLine;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;

  const HomeFeaturedStory({
    required this.badge,
    required this.headline,
    required this.highlightLine,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class HomeEvent {
  final String day;
  final String month;
  final String title;
  final String location;
  final String attendees;

  const HomeEvent({
    required this.day,
    required this.month,
    required this.title,
    required this.location,
    required this.attendees,
  });
}

class HomeCourse {
  final String category;
  final Color categoryColor;
  final String title;
  final String duration;

  const HomeCourse({
    required this.category,
    required this.categoryColor,
    required this.title,
    required this.duration,
  });
}

class HomeCommunity {
  final String name;
  final String memberCount;
  final Color color;
  final String initial;

  const HomeCommunity({
    required this.name,
    required this.memberCount,
    required this.color,
    required this.initial,
  });
}

class HomeLeaderEntry {
  final int rank;
  final String name;
  final String sector;
  final String valuation;
  final String growth;
  final Color color;

  const HomeLeaderEntry({
    required this.rank,
    required this.name,
    required this.sector,
    required this.valuation,
    required this.growth,
    required this.color,
  });
}

class HomeFundingCard {
  final String company;
  final String stage;
  final String amount;
  final String sector;
  final Color color;
  final String initial;

  const HomeFundingCard({
    required this.company,
    required this.stage,
    required this.amount,
    required this.sector,
    required this.color,
    required this.initial,
  });
}

class HomeMockData {
  static const List<HomeFeaturedStory> featured = [
    HomeFeaturedStory(
      badge: 'TOP STORY',
      headline: 'Skyroot Aerospace\nRaises ₹125 Cr',
      highlightLine: 'in Series B Round',
      subtitle: 'Fueling the future of space tech in India.',
      gradientStart: Color(0xFF1A0A2E),
      gradientEnd: Color(0xFF16213E),
    ),
    HomeFeaturedStory(
      badge: 'FUNDING',
      headline: 'Zepto Hits\n\$1.4B Valuation',
      highlightLine: 'in Just 3 Years',
      subtitle: 'From a college project to India\'s fastest-growing startup.',
      gradientStart: Color(0xFF0A1628),
      gradientEnd: Color(0xFF0D2137),
    ),
    HomeFeaturedStory(
      badge: 'SERIES F',
      headline: 'CRED Secures\n\$80M Funding',
      highlightLine: 'to build financial super app',
      subtitle: 'Kunal Shah\'s fintech vision hits new heights.',
      gradientStart: Color(0xFF1C0A0A),
      gradientEnd: Color(0xFF2D1010),
    ),
  ];

  static const List<HomeEvent> events = [
    HomeEvent(
      day: '15',
      month: 'JUN',
      title: 'India Startup Summit 2025',
      location: 'Bengaluru, Karnataka',
      attendees: '2.1K attending',
    ),
    HomeEvent(
      day: '22',
      month: 'JUN',
      title: 'Fintech Innovation Conference',
      location: 'Mumbai, Maharashtra',
      attendees: '890 attending',
    ),
    HomeEvent(
      day: '28',
      month: 'JUN',
      title: 'Women Entrepreneurs Forum',
      location: 'New Delhi',
      attendees: '1.4K attending',
    ),
    HomeEvent(
      day: '05',
      month: 'JUL',
      title: 'AI & Deep Tech Meetup',
      location: 'Hyderabad, Telangana',
      attendees: '620 attending',
    ),
  ];

  static const List<HomeCourse> courses = [
    HomeCourse(
      category: 'FUNDRAISING',
      categoryColor: Color(0xFF00BA88),
      title: 'How to Raise Funds for Your Startup',
      duration: '6:50',
    ),
    HomeCourse(
      category: 'GROWTH',
      categoryColor: Color(0xFFE8341C),
      title: '10 Growth Strategies Every Startup Should Know',
      duration: '7:15',
    ),
    HomeCourse(
      category: 'MARKETING',
      categoryColor: Color(0xFF6C5CE7),
      title: 'Startup Marketing on a Budget That Works',
      duration: '6:30',
    ),
    HomeCourse(
      category: 'BUILD',
      categoryColor: Color(0xFFF4B740),
      title: 'Building a Thought Leadership Brand',
      duration: '5:45',
    ),
    HomeCourse(
      category: 'PRODUCT',
      categoryColor: Color(0xFF0984E3),
      title: 'Product-Market Fit: A Founder\'s Playbook',
      duration: '8:20',
    ),
  ];

  static const List<HomeCommunity> communities = [
    HomeCommunity(
      name: 'Founders Circle',
      memberCount: '12.4K members',
      color: Color(0xFFE8341C),
      initial: 'F',
    ),
    HomeCommunity(
      name: 'Tech Builders India',
      memberCount: '8.2K members',
      color: Color(0xFF0984E3),
      initial: 'T',
    ),
    HomeCommunity(
      name: 'Women in Startups',
      memberCount: '5.7K members',
      color: Color(0xFF6C5CE7),
      initial: 'W',
    ),
    HomeCommunity(
      name: 'Angel Investors Network',
      memberCount: '3.1K members',
      color: Color(0xFF00BA88),
      initial: 'A',
    ),
    HomeCommunity(
      name: 'Early Stage Founders',
      memberCount: '9.8K members',
      color: Color(0xFFF4B740),
      initial: 'E',
    ),
  ];

  static const List<HomeLeaderEntry> leaderboard = [
    HomeLeaderEntry(
      rank: 1,
      name: 'Zepto',
      sector: 'Quick Commerce',
      valuation: '\$1.4B',
      growth: '+142%',
      color: Color(0xFF6C5CE7),
    ),
    HomeLeaderEntry(
      rank: 2,
      name: 'Razorpay',
      sector: 'Fintech',
      valuation: '\$7.5B',
      growth: '+89%',
      color: Color(0xFF0984E3),
    ),
    HomeLeaderEntry(
      rank: 3,
      name: 'Meesho',
      sector: 'Social Commerce',
      valuation: '\$4.9B',
      growth: '+67%',
      color: Color(0xFFE8341C),
    ),
    HomeLeaderEntry(
      rank: 4,
      name: 'CRED',
      sector: 'Fintech',
      valuation: '\$6.4B',
      growth: '+45%',
      color: Color(0xFF00BA88),
    ),
    HomeLeaderEntry(
      rank: 5,
      name: 'boAt',
      sector: 'Consumer Tech',
      valuation: '\$1.2B',
      growth: '+38%',
      color: Color(0xFFF4B740),
    ),
  ];

  static const List<HomeFundingCard> funding = [
    HomeFundingCard(
      company: 'IndiaStar Energy',
      stage: 'Series A',
      amount: '\$12M',
      sector: 'Clean Energy',
      color: Color(0xFF00BA88),
      initial: 'I',
    ),
    HomeFundingCard(
      company: 'EduVerse',
      stage: 'Seed Round',
      amount: '\$3.5M',
      sector: 'EdTech',
      color: Color(0xFF6C5CE7),
      initial: 'E',
    ),
    HomeFundingCard(
      company: 'HealthFirst AI',
      stage: 'Series B',
      amount: '\$25M',
      sector: 'HealthTech',
      color: Color(0xFF0984E3),
      initial: 'H',
    ),
    HomeFundingCard(
      company: 'AgriNext',
      stage: 'Seed Round',
      amount: '\$2M',
      sector: 'AgriTech',
      color: Color(0xFFF4B740),
      initial: 'A',
    ),
  ];
}
