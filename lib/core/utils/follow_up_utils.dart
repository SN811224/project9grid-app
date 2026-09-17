import 'package:flutter/material.dart';

enum FollowUpLight { red, yellow, green }

/// 客戶燈號
/// 綠：30天內
/// 黃：31～40天
/// 紅：41天以上
FollowUpLight customerFollowUpLightFor(DateTime? lastUpdate) {
  if (lastUpdate == null) return FollowUpLight.red;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(
    lastUpdate.year,
    lastUpdate.month,
    lastUpdate.day,
  );

  final days = today.difference(date).inDays;

  if (days <= 30) return FollowUpLight.green;
  if (days <= 40) return FollowUpLight.yellow;
  return FollowUpLight.red;
}

String customerFollowUpLabel(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.green:
      return '30天內有聯絡';
    case FollowUpLight.yellow:
      return '31–40天未聯絡';
    case FollowUpLight.red:
      return '41天以上未聯絡';
  }
}

/// 經營／增員燈號
/// 綠：15天內
/// 黃：16～25天
/// 紅：26天以上
FollowUpLight followUpLightFor(DateTime? lastUpdate) {
  if (lastUpdate == null) return FollowUpLight.red;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(
    lastUpdate.year,
    lastUpdate.month,
    lastUpdate.day,
  );

  final days = today.difference(date).inDays;

  if (days <= 15) return FollowUpLight.green;
  if (days <= 25) return FollowUpLight.yellow;
  return FollowUpLight.red;
}

Color followUpColor(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return Colors.red;
    case FollowUpLight.yellow:
      return Colors.amber.shade700;
    case FollowUpLight.green:
      return Colors.green;
  }
}

String followUpLabel(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return '26天以上未更新';
    case FollowUpLight.yellow:
      return '16–25天未更新';
    case FollowUpLight.green:
      return '15天內有更新';
  }
}

int followUpPriority(FollowUpLight light) {
  switch (light) {
    case FollowUpLight.red:
      return 0;
    case FollowUpLight.yellow:
      return 1;
    case FollowUpLight.green:
      return 2;
  }
}

Widget followUpDot(
  FollowUpLight light, {
  double size = 12,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: followUpColor(light),
      shape: BoxShape.circle,
    ),
  );
}
