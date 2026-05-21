import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPush = 'notif_push';
const _kBreaking = 'notif_breaking';
const _kFunding = 'notif_funding';
const _kSources = 'notif_sources';
const _kAnnouncements = 'notif_announcements';
const _kReplies = 'notif_replies';
const _kFollowers = 'notif_followers';
const _kDigest = 'notif_digest';

class NotificationPrefs {
  final bool pushEnabled;
  final bool breakingNews;
  final bool fundingAlerts;
  final bool followedSources;
  final bool communityAnnouncements;
  final bool repliesAndMentions;
  final bool newFollowers;
  final bool weeklyDigest;

  const NotificationPrefs({
    this.pushEnabled = true,
    this.breakingNews = true,
    this.fundingAlerts = false,
    this.followedSources = true,
    this.communityAnnouncements = true,
    this.repliesAndMentions = true,
    this.newFollowers = true,
    this.weeklyDigest = true,
  });

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? breakingNews,
    bool? fundingAlerts,
    bool? followedSources,
    bool? communityAnnouncements,
    bool? repliesAndMentions,
    bool? newFollowers,
    bool? weeklyDigest,
  }) =>
      NotificationPrefs(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        breakingNews: breakingNews ?? this.breakingNews,
        fundingAlerts: fundingAlerts ?? this.fundingAlerts,
        followedSources: followedSources ?? this.followedSources,
        communityAnnouncements:
            communityAnnouncements ?? this.communityAnnouncements,
        repliesAndMentions: repliesAndMentions ?? this.repliesAndMentions,
        newFollowers: newFollowers ?? this.newFollowers,
        weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      );
}

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      state = NotificationPrefs(
        pushEnabled: p.getBool(_kPush) ?? true,
        breakingNews: p.getBool(_kBreaking) ?? true,
        fundingAlerts: p.getBool(_kFunding) ?? false,
        followedSources: p.getBool(_kSources) ?? true,
        communityAnnouncements: p.getBool(_kAnnouncements) ?? true,
        repliesAndMentions: p.getBool(_kReplies) ?? true,
        newFollowers: p.getBool(_kFollowers) ?? true,
        weeklyDigest: p.getBool(_kDigest) ?? true,
      );
    });
    return const NotificationPrefs();
  }

  Future<void> _save(NotificationPrefs prefs) async {
    state = prefs;
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool(_kPush, prefs.pushEnabled),
      p.setBool(_kBreaking, prefs.breakingNews),
      p.setBool(_kFunding, prefs.fundingAlerts),
      p.setBool(_kSources, prefs.followedSources),
      p.setBool(_kAnnouncements, prefs.communityAnnouncements),
      p.setBool(_kReplies, prefs.repliesAndMentions),
      p.setBool(_kFollowers, prefs.newFollowers),
      p.setBool(_kDigest, prefs.weeklyDigest),
    ]);
  }

  Future<void> setPush(bool v) => _save(state.copyWith(pushEnabled: v));
  Future<void> setBreaking(bool v) => _save(state.copyWith(breakingNews: v));
  Future<void> setFunding(bool v) => _save(state.copyWith(fundingAlerts: v));
  Future<void> setSources(bool v) => _save(state.copyWith(followedSources: v));
  Future<void> setAnnouncements(bool v) =>
      _save(state.copyWith(communityAnnouncements: v));
  Future<void> setReplies(bool v) =>
      _save(state.copyWith(repliesAndMentions: v));
  Future<void> setFollowers(bool v) => _save(state.copyWith(newFollowers: v));
  Future<void> setDigest(bool v) => _save(state.copyWith(weeklyDigest: v));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  NotificationPrefsNotifier.new,
);
