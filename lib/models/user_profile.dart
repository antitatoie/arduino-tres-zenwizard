import 'settings_config.dart';

class UserProfile {
  final String id;
  final String name;
  final String workspaceSubtitle;
  final SettingsConfig settings;
  final int completedSessions;
  final double totalFocusMinutes;

  const UserProfile({
    required this.id,
    required this.name,
    required this.workspaceSubtitle,
    this.settings = const SettingsConfig(),
    this.completedSessions = 0,
    this.totalFocusMinutes = 0.0,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'ZW';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? workspaceSubtitle,
    SettingsConfig? settings,
    int? completedSessions,
    double? totalFocusMinutes,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceSubtitle: workspaceSubtitle ?? this.workspaceSubtitle,
      settings: settings ?? this.settings,
      completedSessions: completedSessions ?? this.completedSessions,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspaceSubtitle': workspaceSubtitle,
      'settings': settings.toJson(),
      'completedSessions': completedSessions,
      'totalFocusMinutes': totalFocusMinutes,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final settingsJson = json['settings'];
    return UserProfile(
      id: json['id']?.toString() ?? 'profile_default',
      name: json['name']?.toString() ?? 'Alex Kim',
      workspaceSubtitle:
          json['workspaceSubtitle']?.toString() ?? 'Desk · Station 01 · Floor 1',
      settings: settingsJson is Map<String, dynamic>
          ? SettingsConfig.fromJson(settingsJson)
          : const SettingsConfig(),
      completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
      totalFocusMinutes: (json['totalFocusMinutes'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
