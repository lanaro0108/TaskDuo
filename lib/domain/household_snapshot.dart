import 'package:flutter/material.dart';

import 'models.dart';

/// Decode and validate the entire save before exposing any of it to the app.
/// Version 1 keeps historical snapshots even when their task was deleted.
class HouseholdSnapshot {
  HouseholdSnapshot(Map<String, dynamic> json)
    : members = (json['members'] as List)
          .map((e) => Member.fromJson(e))
          .toList(),
      tasks = (json['tasks'] as List)
          .map((e) => HouseTask.fromJson(e))
          .toList(),
      completions = (json['completions'] as List)
          .map((e) => Completion.fromJson(e))
          .toList(),
      rewards = (json['rewards'] as List)
          .map((e) => HouseReward.fromJson(e))
          .toList(),
      redemptions = (json['redemptions'] as List)
          .map((e) => Redemption.fromJson(e))
          .toList(),
      activities = (json['activities'] as List)
          .map((e) => HouseActivity.fromJson(e))
          .toList(),
      weeklyBonuses = (json['weeklyBonuses'] as List).cast<String>().toList(),
      activeId = json['activeId'] as String,
      theme = ThemeMode.values.byName(json['theme'] as String),
      notifications = json['notifications'] as bool,
      animations = json['animations'] as bool,
      sounds = json['sounds'] as bool,
      sampleData = json['sampleData'] as bool,
      sequence = json['sequence'] as int? ?? 0 {
    _require(
      json['version'] == 1 || json['version'] == 2,
      'Unsupported storage version',
    );
    if (json['version'] == 2) {
      final key = json['competitionStart'] as String;
      final date = DateTime.tryParse(key);
      _require(
        date != null && dayKey(date) == key && date.weekday == DateTime.monday,
        'Invalid competition start',
      );
    }
    final memberIds = _unique(members.map((m) => m.id));
    _require(
      members.length == 2 && memberIds.contains(activeId),
      'Invalid household',
    );
    _require(sequence >= 0, 'Invalid sequence');
    for (final m in members) {
      _require(
        _text(m.name, 24) &&
            m.avatar >= 0 &&
            m.avatar < avatarOptions.length &&
            m.baseXp >= 0 &&
            m.baseCompleted >= 0,
        'Invalid member',
      );
    }
    _unique(tasks.map((t) => t.id));
    _unique(rewards.map((r) => r.id));
    _unique(redemptions.map((r) => r.id));
    _unique(completions.map((c) => c.taskId));
    _unique(weeklyBonuses);
    for (final key in weeklyBonuses) {
      final date = DateTime.tryParse(key);
      _require(
        date != null && dayKey(date) == key && date.weekday == DateTime.monday,
        'Invalid weekly bonus',
      );
    }
    final completedById = {for (final c in completions) c.taskId: c};
    for (final t in tasks) {
      _require(
        memberIds.contains(t.memberId) &&
            _text(t.title, 70) &&
            t.description.length <= 240 &&
            t.xp >= 0 &&
            t.coins >= 0,
        'Invalid task',
      );
      final c = completedById[t.id];
      _require(t.done == (c != null), 'Inconsistent task history');
      if (c != null) {
        _require(
          c.memberId == t.memberId &&
              c.xp == t.xp &&
              c.coins == t.coins &&
              c.at.isAtSameMomentAs(t.completedAt!) &&
              c.category == t.category,
          'Inconsistent completion',
        );
      }
    }
    for (final c in completions) {
      _require(
        memberIds.contains(c.memberId) &&
            _text(c.title, 70) &&
            c.xp >= 0 &&
            c.coins >= 0,
        'Invalid completion',
      );
    }
    for (final r in rewards) {
      _require(
        _text(r.title, 70) &&
            r.description.length <= 160 &&
            r.cost >= (json['version'] == 1 ? 1 : 0) &&
            r.cost <= 9999 &&
            supportedArtNames.contains(r.art),
        'Invalid reward',
      );
    }
    for (final r in redemptions) {
      _require(
        memberIds.contains(r.memberId) &&
            _text(r.title, 70) &&
            r.cost >= (r.periodKey == null ? 1 : 0) &&
            r.cost <= 9999 &&
            supportedArtNames.contains(r.art),
        'Invalid redemption',
      );
      if (r.periodKey != null) {
        final date = DateTime.tryParse(r.periodKey!);
        _require(
          json['version'] == 2 &&
              r.cost == 0 &&
              date != null &&
              dayKey(date) == r.periodKey &&
              date.weekday == DateTime.monday &&
              !date.isBefore(
                DateTime.parse(json['competitionStart'] as String),
              ),
          'Invalid winning period',
        );
      }
    }
    _unique(redemptions.map((r) => r.periodKey).whereType<String>());
    for (final a in activities) {
      _require(
        a.text.trim().isNotEmpty && supportedArtNames.contains(a.art),
        'Invalid activity',
      );
    }
    for (final id in json['version'] == 1 ? memberIds : <String>{}) {
      final earned = completions
          .where((c) => c.memberId == id)
          .fold(weeklyBonuses.length * 50, (sum, c) => sum + c.coins);
      final spent = redemptions
          .where((r) => r.memberId == id)
          .fold(0, (sum, r) => sum + r.cost);
      _require(earned >= spent, 'Invalid balance');
    }
  }

  final List<Member> members;
  final List<HouseTask> tasks;
  final List<Completion> completions;
  final List<HouseReward> rewards;
  final List<Redemption> redemptions;
  final List<HouseActivity> activities;
  final List<String> weeklyBonuses;
  final String activeId;
  final ThemeMode theme;
  final bool notifications, animations, sounds, sampleData;
  final int sequence;

  static bool _text(String value, int max) =>
      value.trim().isNotEmpty && value.length <= max;
  static void _require(bool valid, String message) {
    if (!valid) throw FormatException(message);
  }

  static Set<String> _unique(Iterable<String> ids) {
    final result = <String>{};
    for (final id in ids) {
      _require(
        id.trim().isNotEmpty && result.add(id),
        'Invalid or duplicate ID',
      );
    }
    return result;
  }
}
